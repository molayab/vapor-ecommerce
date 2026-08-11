import Vapor
import Fluent

/// A terminal replacement for the POS web frontend: lets an operator build and check
/// out an order by hand, without going through the HTTP API.
struct OrderCommand: Command {
    struct Signature: CommandSignature {
        @Argument(name: "subcommand")
        var subcommand: String

        @Option(name: "id")
        var id: String?

        @Option(name: "limit", short: "l")
        var limit: Int?
    }

    var help: String {
"""
Manual, interactive order management (replaces the POS frontend).

subcommands:
 - create
    Walks you through picking a customer, adding product variants and
    checking out, exactly like the old POS screen did.
 - list
    Lists the most recent orders.
    Optional arguments: [--limit]
 - anulate
    Cancels an order, restoring stock and removing its sales.
    --id (transaction id)
"""
    }

    private struct CartItem {
        let variant: ProductVariant
        let quantity: Int
    }

    func run(using context: CommandContext, signature: Signature) throws {
        switch signature.subcommand {
        case "create":
            try create(using: context)
        case "list":
            try list(using: context, signature: signature)
        case "anulate":
            try anulate(using: context, signature: signature)
        default:
            context.console.error("Invalid subcommand: \(signature.subcommand)")
        }
    }

    // MARK: - create

    private func create(using context: CommandContext) throws {
        let app = context.application
        let console = context.console

        let promise = app.eventLoopGroup.makeFutureWithTask {
            try await self.buildAndCheckout(app: app, console: console)
        }
        try promise.wait()
    }

    private func buildAndCheckout(app: Application, console: Console) async throws {
        let db = app.db
        let user = try await resolveCustomer(db: db, console: console)

        var cart = [CartItem]()
        while true {
            guard let item = try await pickItem(db: db, console: console) else {
                break
            }
            cart.append(item)

            if !console.confirm("Add another item?") {
                break
            }
        }

        guard !cart.isEmpty else {
            console.error("No items were added, aborting order.")
            return
        }

        console.info("")
        console.info("Order summary:")
        var subtotal: Double = 0
        for item in cart {
            let lineTotal = item.variant.unitPrice * Double(item.quantity)
            subtotal += lineTotal
            console.info("  \(item.quantity)x \(item.variant.name) (\(item.variant.sku ?? "no-sku")) - \(lineTotal)")
        }
        console.info("  Subtotal: \(subtotal)")

        let methodInput = console.ask("Payment method? [cash/card]").lowercased()
        let origin: Transaction.Origin = methodInput == "card" ? .posCard : .posCash

        guard console.confirm("Confirm checkout for \(user.email)?") else {
            console.warning("Order cancelled.")
            return
        }

        let transaction = try await checkout(db: db, user: user, cart: cart, origin: origin)
        console.success("Order created: \(try transaction.requireID()) - total \(transaction.total) \(transaction.currency.rawValue)")
    }

    private func resolveCustomer(db: Database, console: Console) async throws -> User {
        let email = console.ask("Customer email? (leave empty for a walk-in customer)")

        if email.isEmpty {
            return try await walkInCustomer(db: db)
        }

        if let existing = try await User.query(on: db).filter(\.$email == email).first() {
            return existing
        }

        console.info("No customer found with email \(email), creating one.")
        let name = console.ask("Customer name?")
        return try await User.Create(
            name: name.isEmpty ? "No Name" : name,
            kind: .client,
            password: UUID().uuidString,
            email: email,
            roles: [.noAccess],
            isActive: false,
            addresses: []
        ).create(on: db)
    }

    private func walkInCustomer(db: Database) async throws -> User {
        let walkInEmail = "walk-in@pos.local"
        if let existing = try await User.query(on: db).filter(\.$email == walkInEmail).first() {
            return existing
        }

        return try await User.Create(
            name: "Walk-in Customer",
            kind: .client,
            password: UUID().uuidString,
            email: walkInEmail,
            roles: [.noAccess],
            isActive: false,
            addresses: []
        ).create(on: db)
    }

    private func pickItem(db: Database, console: Console) async throws -> CartItem? {
        let search = console.ask("Product SKU or name? (leave empty to finish)")
        if search.isEmpty {
            return nil
        }

        let matches = try await findVariants(matching: search, db: db)

        guard !matches.isEmpty else {
            console.error("No available product variants matched '\(search)'.")
            return nil
        }

        for (index, variant) in matches.enumerated() {
            console.info("  [\(index)] \(variant.product.title) - \(variant.name) (\(variant.sku ?? "no-sku")) - stock: \(variant.stock) - price: \(variant.unitPrice)")
        }

        guard let indexInput = Int(console.ask("Pick an item")), matches.indices.contains(indexInput) else {
            console.error("Invalid selection.")
            return nil
        }

        let variant = matches[indexInput]
        guard let quantity = Int(console.ask("Quantity?")), quantity > 0 else {
            console.error("Invalid quantity.")
            return nil
        }

        guard variant.stock >= quantity else {
            console.error("Not enough stock: only \(variant.stock) available.")
            return nil
        }

        return CartItem(variant: variant, quantity: quantity)
    }

    private func findVariants(matching search: String, db: Database) async throws -> [ProductVariant] {
        let bySku = try await ProductVariant.query(on: db)
            .filter(\.$sku == search)
            .filter(\.$isAvailable == true)
            .with(\.$product)
            .all()

        if !bySku.isEmpty {
            return bySku
        }

        let byName = try await ProductVariant.query(on: db)
            .filter(\.$name ~~ search)
            .filter(\.$isAvailable == true)
            .with(\.$product)
            .all()

        let matchingProductIds = try await Product.query(on: db)
            .filter(\.$title ~~ search)
            .all()
            .map { try $0.requireID() }

        let byProductTitle: [ProductVariant]
        if matchingProductIds.isEmpty {
            byProductTitle = []
        } else {
            byProductTitle = try await ProductVariant.query(on: db)
                .filter(\.$product.$id ~~ matchingProductIds)
                .filter(\.$isAvailable == true)
                .with(\.$product)
                .all()
        }

        var seen = Set<UUID>()
        var results = [ProductVariant]()
        for variant in byName + byProductTitle {
            guard let id = try? variant.requireID(), !seen.contains(id) else { continue }
            seen.insert(id)
            results.append(variant)
        }

        return results
    }

    private func checkout(db: Database, user: User, cart: [CartItem], origin: Transaction.Origin) async throws -> Transaction {
        try await db.transaction { database in
            let transaction = Transaction()
            transaction.id = UUID()
            transaction.$user.id = try user.requireID()
            transaction.status = .paid
            transaction.origin = origin
            transaction.currency = .COP
            transaction.placedIp = "manual-command"
            transaction.payedAt = Date()
            transaction.shippedAt = Date()
            transaction.orderdAt = Date()
            transaction.tax = 0
            transaction.subtotal = 0
            transaction.total = 0
            try await transaction.save(on: database)

            var subtotal: Double = 0
            var totalTax: Double = 0
            var items = [TransactionItem]()
            var lineTotals = [Double]()

            for cartItem in cart {
                let lineTotal = cartItem.variant.unitPrice * Double(cartItem.quantity)
                subtotal += lineTotal
                totalTax += cartItem.variant.tax
                lineTotals.append(lineTotal)

                let item = TransactionItem()
                item.id = UUID()
                item.$transaction.id = try transaction.requireID()
                item.$productVariant.id = try cartItem.variant.requireID()
                item.quantity = cartItem.quantity
                item.price = lineTotal
                items.append(item)

                cartItem.variant.stock -= cartItem.quantity
                try await cartItem.variant.save(on: database)
            }

            try await items.create(on: database)

            transaction.tax = totalTax / Double(cart.count)
            transaction.subtotal = subtotal
            transaction.total = subtotal + (subtotal * transaction.tax)
            try await transaction.save(on: database)

            let sales = try lineTotals.map { lineTotal -> Sale in
                let sale = Sale()
                sale.id = UUID()
                sale.$order.id = try transaction.requireID()
                sale.currency = .COP
                sale.amount = lineTotal + (lineTotal * transaction.tax)
                sale.date = Date()
                sale.type = .sale
                return sale
            }
            try await sales.create(on: database)

            return transaction
        }
    }

    // MARK: - list

    private func list(using context: CommandContext, signature: Signature) throws {
        let limit = signature.limit ?? 20
        let transactions = try Transaction.query(on: context.application.db)
            .sort(\.$createdAt, .descending)
            .limit(limit)
            .with(\.$user)
            .all()
            .wait()

        for transaction in transactions {
            let id = (try? transaction.requireID().uuidString) ?? "unknown"
            context.console.info("\(id) - \(transaction.status.rawValue) - \(transaction.origin.rawValue) - \(transaction.total) \(transaction.currency.rawValue) - \(transaction.user.email)")
        }
    }

    // MARK: - anulate

    private func anulate(using context: CommandContext, signature: Signature) throws {
        guard let idString = signature.id, let id = UUID(uuidString: idString) else {
            context.console.error("Missing or invalid required argument: --id")
            return
        }

        guard context.console.confirm("Anulate order \(id)? This will restore stock and remove its sales.") else {
            context.console.warning("Aborted.")
            return
        }

        let app = context.application
        let promise = app.eventLoopGroup.makeFutureWithTask {
            try await app.db.transaction { database in
                guard let transaction = try await Transaction.find(id, on: database) else {
                    throw Abort(.notFound)
                }

                for item in try await transaction.$items.get(on: database) {
                    let variant = try await item.$productVariant.get(on: database)
                    variant.stock += item.quantity
                    try await variant.save(on: database)
                }

                try await Sale.query(on: database)
                    .filter(\.$order.$id == transaction.requireID())
                    .delete()
                try await transaction.$items.get(on: database).delete(on: database)
                try await transaction.delete(on: database)
            }
        }

        try promise.wait()
        context.console.success("Order \(id) anulated.")
    }
}

private extension ProductVariant {
    var unitPrice: Double {
        salePrice > 0 ? salePrice : price
    }
}
