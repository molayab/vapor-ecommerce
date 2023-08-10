import Vapor
import Fluent
import Queues

final class Finance: Model {
    static let schema = "finances"
    enum FinanceType: String, Codable {
        case income
        case expense
    }
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "description")
    var description: String?
    
    @Field(key: "amount")
    var amount: Double
    
    @Enum(key: "currency")
    var currency: Currency
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Enum(key: "type")
    var type: FinanceType
}

extension Finance {
    struct Create: Content {
        var name: String
        var description: String?
        var amount: Double
        var currency: Currency
        var type: FinanceType
        
        func createModel() -> Finance {
            let finance = Finance()
            finance.name = name
            finance.description = description
            finance.amount = amount
            finance.currency = currency
            finance.type = type
            return finance
        }
    }
    
    typealias Update = Create
    typealias Public = Create
}

extension Finance.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("amount", as: Double.self)
        validations.add("currency", as: Currency.self)
        validations.add("type", as: Finance.FinanceType.self)
    }
}

extension Finance {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Finance.schema)
                .id()
                .field("name", .string, .required)
                .field("description", .string)
                .field("amount", .double, .required)
                .field("currency", .string, .required)
                .field("created_at", .datetime)
                .field("updated_at", .datetime)
                .field("type", .string, .required)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Finance.schema).delete()
        }
    }
}
