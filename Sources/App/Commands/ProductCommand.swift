import Vapor
import Fluent
import Fakery

struct ProductCommand: Command {
    struct Signature: CommandSignature {
        @Argument(name: "subcommand")
        var subcommand: String
    }

    var help: String {
        ""
    }

    func run(using context: CommandContext, signature: Signature) throws {
        switch signature.subcommand {
        case "create":
            try create(using: context, signature: signature)
        case "list":
            try list(using: context, signature: signature)
        case "delete":
            try delete(using: context, signature: signature)
        case "randomize":
            try randomizeTxs(using: context, signature: signature)
        default:
            context.console.error("Invalid subcommand: \(signature.subcommand)")

        }
    }

    private func randomizeTxs(using context: CommandContext, signature: Signature) throws {
        let products = try Product.query(on: context.application.db).all().wait()
        let users = try User.query(on: context.application.db).all().wait()

        var txs = [Transaction]()
        var items = [TransactionItem]()

        for _ in 0..<1000 {
            let product = products.randomElement()!
            let variant = try product.$variants.get(on: context.application.db).wait().randomElement()!

            let tx = Transaction()
            tx.id = UUID()
            tx.origin = .web
            tx.status = .paid
            // Get a random date between 3 year ago and now
            tx.payedAt = Date(timeIntervalSinceNow: -TimeInterval.random(in: 0...94608000))
            tx.shippedAt = Date()
            tx.orderdAt = Date()
            tx.placedIp = "127.0.0.1"

            if let user = users.randomElement() {
                tx.$user.id = try user.requireID()
            }

            txs.append(tx)

            let item = TransactionItem()
            item.id = UUID()
            item.$transaction.id = try tx.requireID()
            item.$productVariant.id = try variant.requireID()
            item.quantity = Int.random(in: 1...10)
            item.price = variant.price * Double(item.quantity)

            items.append(item)
        }

        try txs.create(on: context.application.db).wait()
        try items.create(on: context.application.db).wait()

    }

    private func delete(using context: CommandContext, signature: Signature) throws {
        let id = context.console.ask("Product ID?")
        guard let uuid = UUID(uuidString: id) else {
            context.console.error("Invalid UUID: \(id)")
            return
        }

        guard let product = try Product.find(uuid, on: context.application.db).wait() else {
            context.console.error("No product found with ID: \(id)")
            return
        }

        let variants = try product.$variants.get(on: context.application.db).wait()

        try variants.delete(on: context.application.db).wait()
        try product.delete(on: context.application.db).wait()
        context.console.info("Product deleted")
    }

    private func list(using context: CommandContext, signature: Signature) throws {
        let products = try Product.query(on: context.application.db).all().wait()
        for product in products {
            context.console.info("\(product.id ?? UUID()) - \(product.title)")

            for variant in try product.$variants.get(on: context.application.db).wait() {
                context.console.info("  - \(variant.name) - \(variant.price)")
            }
        }
    }

    private func create(using context: CommandContext, signature: Signature) throws {
        while true {
            var categoryId: UUID?

            let title = context.console.ask("Product title?")
            let description = context.console.ask("Product description?")
            let category = context.console.ask("Product category?")
            let model = Product()
            model.id = UUID()
            model.title = title
            model.description = description

            // Find category
            let categories = try Category.query(on: context.application.db)
                .filter(\.$title == category).all().wait()

            if categories.isEmpty {
                context.console.error("No category found with title: \(category)")
                context.console.info("Creating category: \(category)")

                let category = Category(model: Category.Create(title: category))
                try category.save(on: context.application.db).wait()

                categoryId = try category.requireID()
            } else {
                categoryId = try categories.first?.requireID()
            }

            var variants = [ProductVariant]()
            while true {
                let name = context.console.ask("Variant name?")
                let salePrice = Double(context.console.ask("Variant sale price?")) ?? 0.0
                let price = Double(context.console.ask("Variant price?")) ?? 0.0
                let isAvailable = context.console.confirm("Variant available?")

                let variant = ProductVariant()
                variant.name = name
                variant.salePrice = salePrice
                variant.price = price
                variant.isAvailable = isAvailable
                variant.$product.id = try model.requireID()

                variants.append(variant)
                if !context.console.confirm("Add another variant?") {
                    break
                }
            }

            model.$category.id = categoryId ?? UUID()
            try model.save(on: context.application.db).wait()

            context.console.info("Product created: \(model.title)")
            try variants.create(on: context.application.db).wait()

            if !context.console.confirm("Create another product?") {
                break
            }
        }
    }

}
