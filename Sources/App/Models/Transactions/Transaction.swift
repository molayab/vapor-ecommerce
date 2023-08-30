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

    func asPublic(on db: Database) async throws -> Public {
        let sales = try await self.$items.get(on: db).get()

        return try .init(
            id: requireID().uuidString,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            items: sales.map { try $0.asPublic() },
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

        var total: Double {
            items?.reduce(0) { $0 + $1.total } ?? 0
        }
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

    struct Create: Content {
        var shippingAddressId: UUID?
        var billingAddressId: UUID?
        var items: [TransactionItem.Create]

        func create(in req: Request, forOrigin origin: Transaction.Origin) async throws -> Transaction {
            let user = try req.auth.require(User.self)
            let model = Transaction()

            return try await req.db.transaction { database in 
                model.$user.id = try user.requireID()
                model.$shippingAddress.id = shippingAddressId
                model.$billingAddress.id = billingAddressId
                model.status = .placed
                model.placedIp = req.headers.first(name: .xForwardedFor)
                    ?? req.remoteAddress?.hostname
                    ?? "unknown"
                model.origin = origin

                if origin == .posCard || origin == .posCash {
                    model.status = .paid
                    model.payedAt = Date()
                    model.shippedAt = Date()
                    model.orderdAt = Date()
                }

                try await model.save(on: database)
                try await items.asyncMap { item in
                    // Check variant stock
                    guard let variant = try await ProductVariant.find(item.productVariantId, on: database) else {
                        throw Abort(.badRequest, reason: "Product variant not found")
                    }
                    guard variant.stock >= item.quantity else {
                        throw Abort(.badRequest, reason: "Product variant out of stock")
                    }

                    let mod = item.create()
                    mod.$transaction.$id.wrappedValue = try model.requireID()
                    return mod
                }.create(on: database)

                // Update stock
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
                        record.currency = sale.currency
                        record.amount = Double(sale.quantity) * sale.price
                        record.date = Date()
                        record.type = .sale
                        return record
                    }.create(on: database)
                }

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
}
