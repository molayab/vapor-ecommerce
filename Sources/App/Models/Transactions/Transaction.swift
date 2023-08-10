import Vapor
import Fluent

final class Transaction: Model {
    enum Status: String, Codable {
        case pending
        case paid
        case shipped
        case delivered
        case canceled
        case declined
        case placed
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
    
    @Parent(key: "shipping_address_id")
    var shippingAddress: Address
    
    @Parent(key: "billing_address_id")
    var billingAddress: Address
    
    @Field(key: "payed_at")
    var payedAt: Date?
    
    @Field(key: "shipped_at")
    var shippedAt: Date?
    
    @Field(key: "orderd_at")
    var orderdAt: Date?
    
    @Field(key: "canceled_at")
    var canceledAt: Date?
    
    @Field(key: "placed_ip")
    var placedIp: String?
    
    func asPublic(on db: Database) async throws -> Public {
        .init(
            id: try requireID().uuidString,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            items: try await $items.get(on: db).asyncMap { try await $0.asPublic(on: db) },
            shippingAddress: shippingAddress.asPublic(),
            billingAddress: billingAddress.asPublic(),
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
    
    struct Create: Content {
        var shippingAddressId: UUID
        var billingAddressId: UUID
        var items: [TransactionItem.Create]
        
        func create(in req: Request) async throws -> Transaction {
            let user = try req.auth.require(User.self)
            let model = Transaction()
            model.$user.id = try user.requireID()
            model.$shippingAddress.id = shippingAddressId
            model.$billingAddress.id = billingAddressId
            model.status = .placed
            model.placedIp = req.headers.first(name: .xForwardedFor)
                ?? req.remoteAddress?.hostname
                ?? "unknown"
            try await model.save(on: req.db)
            
            try await items.map { item in
                item.create()
            }.create(on: req.db)
            
            return model
        }
    }
}

extension Transaction.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("userId", as: UUID.self)
        validations.add("shippingAddressId", as: UUID.self)
        validations.add("billingAddressId", as: UUID.self)
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
                .field("shipping_address_id", .uuid, .required, .references("addresses", "id"))
                .field("billing_address_id", .uuid, .required, .references("addresses", "id"))
                .field("payed_at", .datetime)
                .field("shipped_at", .datetime)
                .field("orderd_at", .datetime)
                .field("canceled_at", .datetime)
                .field("placed_ip", .string)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Transaction.schema).delete()
        }
    }
}
