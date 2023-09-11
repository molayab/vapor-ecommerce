import Vapor
import Fluent

/// Costs are expenses that are paid periodically
final class Cost: Model {
    /// The type of cost
    enum CostType: String, Codable {
        case fixed
        case variable
    }

    static let schema = "costs"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "amount")
    var amount: Double

    @Enum(key: "currency")
    var currency: Currency

    @Enum(key: "type")
    var type: CostType

    @Field(key: "start_date")
    var startDate: Date

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?


    func asPublic() throws -> Public {
        Public(
            id: try requireID(),
            name: name,
            amount: amount,
            currency: currency,
            type: type,
            startDate: startDate)
    }

}

extension Cost {
    struct Create: Content {
        var name: String
        var amount: Double
        var currency: Currency
        var type: CostType
        var startDate: Date

        func createModel() -> Cost {
            let cost = Cost()
            cost.name = name
            cost.amount = amount
            cost.currency = currency
            cost.type = type
            cost.startDate = startDate
            return cost
        }
    }

    typealias Update = Create
    struct Public: Content {
        var id: UUID
        var name: String
        var amount: Double
        var currency: Currency
        var type: CostType
        var startDate: Date
    }
}

extension Cost.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("amount", as: Double.self, is: .range(0...))
        validations.add("currency", as: Currency.self)
        validations.add("type", as: Cost.CostType.self)
        validations.add("startDate", as: Date.self)
    }
}

extension Cost {
    struct CreateMigration: AsyncMigration {
        func prepare(on db: Database) async throws {
            try await db.schema(Cost.schema)
                .id()
                .field("name", .string, .required)
                .field("amount", .double, .required)
                .field("currency", .string, .required)
                .field("type", .string, .required)
                .field("periodicity", .string, .required)
                .field("start_date", .datetime, .required)
                .field("created_at", .datetime)
                .field("updated_at", .datetime)
                .create()
        }

        func revert(on db: Database) async throws {
            try await db.schema(Cost.schema).delete()
        }
    }
    
    struct RemovePeriodicityFieldMigration: AsyncMigration {
        func prepare(on db: Database) async throws {
            try await db.schema(Cost.schema)
                .deleteField("periodicity")
                .update()
        }

        func revert(on db: Database) async throws {
            try await db.schema(Cost.schema)
                .field("periodicity", .string, .required)
                .update()
        }
    }
    
    struct AddDeletedAtFieldMigration: AsyncMigration {
        func prepare(on db: Database) async throws {
            try await db.schema(Cost.schema)
                .field("deleted_at", .datetime)
                .update()
        }

        func revert(on db: Database) async throws {
            try await db.schema(Cost.schema)
                .deleteField("deleted_at")
                .update()
        }
    }
}
