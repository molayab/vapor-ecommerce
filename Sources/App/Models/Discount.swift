import Vapor
import Fluent

final class Discount: Model {
    enum PromoType: String, Codable {
        case percentage
        case fixed
        
        // This is used for special cases, when there is a refund and you
        // issue a promo code for the refund amount. In that case you have
        // the money of the previous transaction, so you don't want to charge again.
        case fixedNoCharge
    }

    static var schema: String = "discounts"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "code")
    var code: String

    @Field(key: "discount")
    var discount: Double

    @Enum(key: "type")
    var type: PromoType

    @Field(key: "is_active")
    var isActive: Bool
    
    @Field(key: "used_at")
    var usedAt: Date?
    
    @Field(key: "expires_at")
    var expiresAt: Date

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    /// This method is used to create a new promo code.
    /// - Parameters:
    ///  - discount: The discount amount.
    ///  - type: The type of discount.
    ///  - expiresAt: The expiration date of the promo code.
    ///  - db: The database to run the query on.
    /// - Returns: A new promo code.
    /// - Warning: This method will recursively call itself if the generated code is not unique.
    /// - Warning: The promo is active by default.
    static func create(discount: Double, type: PromoType, expiresAt: Date, on db: Database) async throws -> Discount {
        let code = generateCode()
        
        // Check if code is unique
        let existingPromo = try await Discount.query(on: db)
            .filter(\.$code == code)
            .first()
        
        if existingPromo != nil {
            return try await create(discount: discount, type: type, expiresAt: expiresAt, on: db)
        }
        
        let promo = Discount()
        promo.code = code
        promo.discount = discount
        promo.type = type
        promo.isActive = true
        promo.expiresAt = expiresAt
        
        try await promo.save(on: db)
        return promo
    }
    
    static func generateCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map{ _ in letters.randomElement() ?? "X" })
    }
    
    func asPublic() throws -> Public {
        return try .init(
            id: requireID(),
            code: code,
            discount: discount,
            type: type,
            isActive: isActive,
            usedAt: usedAt,
            expiresAt: expiresAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension Discount {
    struct Public: Content {
        var id: UUID
        var code: String
        var discount: Double
        var type: PromoType
        var isActive: Bool
        var usedAt: Date?
        var expiresAt: Date
        var createdAt: Date?
        var updatedAt: Date?
    }
}

extension Discount {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Discount.schema)
                .id()
                .field("code", .string, .required)
                .field("discount", .double, .required)
                .field("type", .string, .required)
                .field("is_active", .bool, .required)
                .field("used_at", .datetime)
                .field("expires_at", .datetime, .required)
                .field("created_at", .datetime)
                .field("updated_at", .datetime)
                .unique(on: "code")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(Discount.schema).delete()
        }
    }
}
