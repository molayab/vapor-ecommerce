import Vapor
import Fluent

final class Transaction: Model {
    /// The status of the transaction.
    enum Status: String, Codable {
        case pending
        case paid
        case shipped
        case delivered
        case canceled
        case declined
        case placed
    }

    /// The origin of the transaction.
    enum Origin: String, Codable, CaseIterable {
        case web
        case posCash
        case posCard
    }

    static var schema: String = "transactions"

    @ID(key: .id)
    var id: UUID?

    @Enum(key: "status")
    var status: Status

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Parent(key: "user_id")
    var user: User

    @Children(for: \.$transaction)
    var items: [TransactionItem]

    @OptionalParent(key: "shipping_address_id")
    var shippingAddress: Address?

    @OptionalParent(key: "billing_address_id")
    var billingAddress: Address?

    @OptionalField(key: "payed_at")
    var payedAt: Date?

    @OptionalField(key: "shipped_at")
    var shippedAt: Date?

    @OptionalField(key: "orderd_at")
    var orderdAt: Date?

    @OptionalField(key: "canceled_at")
    var canceledAt: Date?

    @OptionalField(key: "placed_ip")
    var placedIp: String?

    @Enum(key: "origin")
    var origin: Origin
    
    @Children(for: \.$order)
    var sales: [Sale]
    
    @OptionalParent(key: "discount_id")
    var discount: Discount?
    
    @Field(key: "subtotal")
    var subtotal: Double
    
    @Field(key: "tax")
    var tax: Double
    
    @Field(key: "total")
    var total: Double
    
    @Enum(key: "currency")
    var currency: Currency

    func asPublic(request: Request) async throws -> Public {
        let sales = try await self.$items.get(on: request.db).get()

        return try .init(
            id: requireID().uuidString,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            items: try await sales.asyncMap { try await $0.asPublic(request: request) },
            shippingAddress: shippingAddress?.asPublic(),
            billingAddress: billingAddress?.asPublic(),
            payedAt: payedAt,
            shippedAt: shippedAt,
            orderdAt: orderdAt,
            canceledAt: canceledAt,
            placedIp: placedIp
        )
    }
}

extension Transaction {
    struct Public: Content {
        var id: String
        var status: Status
        var createdAt: Date?
        var updatedAt: Date?
        var items: [TransactionItem.Public]?
        var shippingAddress: Address.Public?
        var billingAddress: Address.Public?
        var payedAt: Date?
        var shippedAt: Date?
        var orderdAt: Date?
        var canceledAt: Date?
        var placedIp: String?
        var discount: Discount.Public?
    }

    struct Anulate: Content {
        /// The id of the transaction to anulate.
        var id: UUID

        /**
         * Anulates a transaction.
         * When anulating a transaction, the stock of the products is restored, and the sales are removed.
         * This is a destructive operation.
         */
        @discardableResult
        func anulate(in req: Request) async throws -> Transaction {
            return try await req.db.transaction { database in
                guard let model = try await Transaction.find(id, on: database) else {
                    throw Abort(.notFound)
                }

                // Update stock
                for item in try await model.$items.get(on: database) {
                    let product = try await item.$productVariant.get(on: database).get()
                    product.stock += item.quantity
                    try await product.save(on: database)
                }

                // Remove sales
                try await Sale.query(on: database)
                    .filter(\.$order.$id == model.requireID())
                    .delete()

                try await model.$items.get(on: database).delete(on: database)
                try await model.delete(on: database)

                return model
            }
        }
    }

    struct BillTo: Content, Validatable, Decodable {
        var name: String
        var email: String

        static func validations(_ validations: inout Validations) {
            validations.add("name", as: String.self, is: !.empty)
            validations.add("email", as: String.self, is: .email)
        }
    }

    struct Return: Content, Validatable {
        var transactionId: UUID
        var skus: [String]

        static func validations(_ validations: inout Validations) {
            validations.add("transactionId", as: UUID.self)
            validations.add("skus", as: [String].self)
        }

        func `return`(in req: Request) async throws -> (tx: Transaction, total: Double)  {
            return try await req.db.transaction { database in
                guard let model = try await Transaction.find(transactionId, on: database) else {
                    throw Abort(.notFound)
                }

                // Get the SKUs to return
                var total: Double = 0
                for sku in skus {
                    guard let item = try await model.$items
                        .query(on: database)
                        .join(ProductVariant.self, on: \TransactionItem.$productVariant.$id == \ProductVariant.$id)
                        .filter(ProductVariant.self, \ProductVariant.$sku == sku)
                        .first() else {
                            throw Abort(.notFound)
                    }

                    // Update stock
                    let product = try await item.$productVariant.get(on: database).get()
                    product.stock += item.quantity
                    try await product.save(on: database)

                    // Add refund to sales
                    let record = Sale()
                    record.$order.id = try model.requireID()
                    let subtotal = item.price + (item.price * model.tax)
                    record.currency = model.currency
                    record.amount = subtotal * -1
                    record.date = Date()
                    record.type = .refund
                    
                    total += record.amount
                    try await record.save(on: database)
                    
                    if item.quantity > 1 {
                        // Update the quantity of the item
                        let individualPrice = item.price / Double(item.quantity)
                        item.quantity -= 1
                        item.price = individualPrice * Double(item.quantity)
                        
                        try await item.save(on: database)
                    } else {
                        // Remove the item
                        try await item.delete(on: database)
                    }

                    // If all items are returned, cancel the transaction
                    let items = try await model.$items.get(on: database)
                    if items.count == 0 {
                        model.status = .canceled
                        model.canceledAt = Date()
                        try await model.save(on: database)

                        // Also remove the sales
                        try await Sale.query(on: database)
                            .filter(\.$order.$id == model.requireID())
                            .delete()
                    }
                    
                    // Update the transaction total, subtotal and tax
                    try await req
                        .queue
                        .dispatch(TransactionCheckerJob.self,
                                  model.requireID() as TransactionCheckerJob.Payload)
                }
                
                return (model, total)
            }
        }
    }

    struct Create: Content {
        var shippingAddressId: UUID?
        var billingAddressId: UUID?
        var items: [TransactionItem.Create]
        var billTo: BillTo?
        var promoCode: String?

        func create(in req: Request, forOrigin origin: Transaction.Origin) async throws -> Transaction {
            var user = try req.auth.require(User.self)
            let model = Transaction()

            if let billTo = billTo, !billTo.email.isEmpty {
                let emailPattern = #"^\S+@\S+\.\S+$"#
                let result = billTo.email.range(
                    of: emailPattern,
                    options: .regularExpression
                )

                let validEmail = (result != nil)

                // Search the email in the database
                if let userContext = try await User.query(on: req.db).filter(\.$email == billTo.email).first() {
                    user = userContext
                } else if validEmail {
                    // The user does not exist, so we create it
                    let payload = User.Create(
                        name: billTo.name,
                        kind: .client,
                        password: UUID().uuidString,
                        email: billTo.email,
                        roles: [.noAccess],
                        isActive: false,
                        addresses: []
                    )

                    user = try await payload.create(on: req.db)
                } else {
                    await req.notifyMessage("Correo electrónico inválido")
                    throw Abort(.badRequest, reason: "Invalid email")
                }
            }

            let userRef = user
            return try await req.db.transaction { database in
                model.$user.id = try userRef.requireID()
                model.$shippingAddress.id = shippingAddressId
                model.$billingAddress.id = billingAddressId
                model.status = .placed
                model.placedIp = req.headers.first(name: .xForwardedFor)
                    ?? req.remoteAddress?.hostname
                    ?? "unknown"
                model.origin = origin
                model.currency = .COP
                model.tax = 0

                if origin == .posCard || origin == .posCash {
                    model.status = .paid
                    model.payedAt = Date()
                    model.shippedAt = Date()
                    model.orderdAt = Date()
                }

                // Create transaction
                try await model.save(on: database)

                // Create transaction items
                try await items.asyncMap { item in
                    // Check variant stock
                    guard let variant = try await ProductVariant.find(item.productVariantId, on: database) else {
                        await req.notifyMessage("Variante no encontrada")
                        throw Abort(.badRequest, reason: "Product variant not found")
                    }
                    guard variant.stock >= item.quantity else {
                        await req.notifyMessage("Variante sin stock (No hay \(item.quantity) disponibles).")
                        throw Abort(.badRequest, reason: "Product variant out of stock")
                    }
                    
                    model.tax += variant.tax

                    let mod = item.create()
                    mod.$transaction.$id.wrappedValue = try model.requireID()
                    return mod
                }.create(on: database)
                
                model.tax = model.tax / Double(items.count)
                
                // Apply promo code if applicable
                if let promoCode, let discount = try? await Discount.query(on: database)
                        .filter(\.$code == promoCode)
                        .first() {
                    
                    // Check if the promo code is valid
                    if discount.isActive && discount.expiresAt > Date() {
                        model.$discount.id = try discount.requireID()
                        discount.isActive.toggle()
                        discount.usedAt = Date()
                        discount.code = UUID().uuidString.sha256()
                        try await discount.save(on: database)
                    }
                }

                // Update stock: we are selling products, therefore we need decrease the stock
                for item in try await model.$items.get(on: database).get() {
                    let product = try await item.$productVariant.get(on: database).get()
                    product.stock -= item.quantity
                    try await product.save(on: database)
                }

                // If the order is paid, add a sales record
                if model.status == .paid {
                    let sales = try await model.$items.get(on: database).get()
                    try await sales.asyncMap { sale in
                        let record = Sale()
                        record.$order.id = try model.requireID()
                        record.currency = model.currency
                        record.amount = sale.price + (sale.price * model.tax)
                        record.date = Date()
                        record.type = .sale
                        return record
                    }.create(on: database)
                }
                
                // Update the transaction total, subtotal and tax
                try await model.save(on: database)
                try await req
                    .queue
                    .dispatch(TransactionCheckerJob.self,
                              model.requireID() as TransactionCheckerJob.Payload)

                return model
            }
        }
    }
}

extension Transaction.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("shippingAddressId", as: UUID?.self)
        validations.add("billingAddressId", as: UUID?.self)
        validations.add("items", as: [TransactionItem.Create].self)
    }
}

extension Transaction {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Transaction.schema)
                .id()
                .field("status", .string, .required)
                .field("created_at", .datetime)
                .field("updated_at", .datetime)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .field("shipping_address_id", .uuid, .references("addresses", "id"))
                .field("billing_address_id", .uuid, .references("addresses", "id"))
                .field("payed_at", .datetime)
                .field("shipped_at", .datetime)
                .field("orderd_at", .datetime)
                .field("canceled_at", .datetime)
                .field("placed_ip", .string)
                .field("origin", .string, .required)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(Transaction.schema).delete()
        }
    }
    
    struct AddDiscountFieldMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Transaction.schema)
                .field("discount_id", .uuid, .references("discounts", "id"))
                .update()
        }

        func revert(on database: Database) async throws {
            try await database.schema(Transaction.schema)
                .deleteField("discount_id")
                .update()
        }
    }
    
    struct AddTransactionFinancialFieldsMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Transaction.schema)
                .field("currency", .string, .required, .custom("DEFAULT 'unknown'"))
                .field("subtotal", .double, .required, .custom("DEFAULT 0"))
                .field("tax", .double, .required, .custom("DEFAULT 0"))
                .field("total", .double, .required, .custom("DEFAULT 0"))
                .update()
        }

        func revert(on database: Database) async throws {
            try await database.schema(Transaction.schema)
                .deleteField("currency")
                .deleteField("subtotal")
                .deleteField("tax")
                .deleteField("total")
                .update()
        }
    }
    
}

extension Transaction {
    func generateEmailConfirmation(database: Database) async throws -> String {
        let model = try await $items.get(on: database)
        let items = try await model.asyncMap { item in
            try await $user.load(on: database)
            let variant = try await item.$productVariant.get(on: database)
            let product = try await variant.$product.get(on: database)
            let total = String(format: "%.0f", item.price * Double(item.quantity))

            return "<li><i><b>" 
                + product.title + " "
                + variant.name + "(\(item.quantity))</b> - $"
                + total + "</i></li>"
        }.joined(separator: "\n")

        let user = try await $user.get(on: database)
        let txTotal = String(
            format: "%.0f",
            try await $items.get(
                on: database)
            .reduce(0) {
                $0 + $1.price * Double($1.quantity)
                    + ($1.price * Double($1.quantity) * self.tax) })

        return
"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Confirmación de Compra</title>
</head>
<body style="font-family: Arial, sans-serif; background-color: #f0f0f0; padding: 20px;">

    <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 20px; border-radius: 5px; box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);">
        <h2 style="color: #333;">Confirmación de Compra</h2>
        <p>Estimado(a) \(user.name.isEmpty ? user.email : user.name.capitalized),</p>
        <p>Gracias por su compra en nuestra tienda. A continuación, encontrará los detalles de su compra:</p>
        <ul>
            \(items)
        </ul>
        <p>Total: $\(txTotal)</p>
        <p>Le enviamos este correo electrónico de confirmación para informarle que su compra ha sido procesada con éxito.</p>
        <p>Si tiene alguna pregunta o necesita asistencia adicional, no dude en ponerse en contacto con nuestro servicio al cliente en \(settings.contactEmail).</p>
        <p>Gracias por elegirnos. ¡Esperamos que disfrute de sus productos!</p>

        <h3 style="color: #333;">Si desea hacer efectivo algún cambio:</h3>
        <p>Para hacer efectivo un cambio o devolución, por favor conserve este correo electrónico y el articulo en su empaque original y buen estado. A continuación, su guía para hacer efectivo el cambio o devolución. Esta guía es válida por 30 días a partir de la fecha de compra.</p>
        <h2 style="color: #333;">\(try requireID().uuidString)</h2>

        <p>Atentamente,<br>\(settings.siteName)</p>
    </div>

</body>
</html>
"""
    }
}
