import Vapor
import Fluent

import Queues

final class Sale: Model {
    /// The type of sale
    enum SaleType: String, Codable {
        case sale
        case refund
    }
    
    static let schema = "sales"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "type")
    var type: SaleType
    
    @Field(key: "amount")
    var amount: Double
    
    @Field(key: "currency")
    var currency: Currency
    
    @Field(key: "date")
    var date: Date
    
    @Parent(key: "transaction_id")
    var order: Transaction
    
    struct Public: Content {
        var id: UUID?
        var type: SaleType
        var amount: Double
        var currency: Currency
        var date: Date
    }
    
    func asPublic() -> Public {
        return Public(id: id, type: type, amount: amount, currency: currency, date: date)
    }
}

extension Sale {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Sale.schema)
                .id()
                .field("type", .string, .required)
                .field("amount", .double, .required)
                .field("currency", .string, .required)
                .field("date", .datetime, .required)
                .field("transaction_id", .uuid, .required, .references(Transaction.schema, "id"))
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Sale.schema).delete()
        }
    }
}



/// A scheduled job that runs every day at 00:00
struct CostShedulerJob: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        // Fetch all costs
        let costs = try await Cost.query(on: context.application.db).all()
        
        // Check for recurring costs
        try await withThrowingTaskGroup(of: Void.self, body: { group in
            for cost in costs {
                group.addTask {
                    try await cost.checkForRecurringCosts(on: context.application.db)
                }
            }
            
            try await group.waitForAll()
        })
    }
}

/// Costs are expenses that are paid periodically
final class Cost: Model {
    /// The type of cost
    enum CostType: String, Codable {
        case fixed
        case variable
    }
    
    /// How often the cost is paid
    enum Periodicity: String, Codable {
        // One time cost
        case oneTime
        
        // Recurring costs
        case daily // Every day
        case weekly // Every week
        case biweekly // Every two weeks
        case monthly // Every month
        case bimonthly // Every two months
        case quarterly // Every three months
        case semiannually // Every six months
        case yearly // Every year
        
        func shouldApplyFinance(date: Date) -> Bool {
            switch self {
            case .oneTime:
                return false
            case .daily:
                return true
            case .weekly:
                return Calendar.current.component(.weekday, from: date)
                    == Calendar.current.component(.weekday, from: Date())
            case .biweekly:
                return Calendar.current.component(.weekday, from: date)
                    == Calendar.current.component(.weekday, from: Date())
                    && Calendar.current.component(.weekOfMonth, from: date) % 2 == 0
            case .monthly:
                return Calendar.current.component(.day, from: date)
                    == Calendar.current.component(.day, from: Date())
            case .bimonthly:
                return Calendar.current.component(.day, from: date)
                    == Calendar.current.component(.day, from: Date())
                    && Calendar.current.component(.month, from: date) % 2 == 0
            case .quarterly:
                return Calendar.current.component(.day, from: date)
                    == Calendar.current.component(.day, from: Date())
                    && Calendar.current.component(.month, from: date) % 3 == 0
            case .semiannually:
                return Calendar.current.component(.day, from: date)
                    == Calendar.current.component(.day, from: Date())
                    && Calendar.current.component(.month, from: date) % 6 == 0
            case .yearly:
                return Calendar.current.component(.day, from: date)
                    == Calendar.current.component(.day, from: Date())
                    && Calendar.current.component(.month, from: date)
                        == Calendar.current.component(.month, from: Date())
            }
        }
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
    
    @Enum(key: "periodicity")
    var periodicity: Periodicity
    
    @Field(key: "start_date")
    var startDate: Date
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    /// Check if the cost should be applied as a finance
    func checkForRecurringCosts(on db: Database) async throws {
        guard periodicity.shouldApplyFinance(date: startDate) else { return }
        
        let finance = Finance()
        finance.name = name
        finance.amount = amount
        finance.currency = currency
        finance.type = .expense
        try await finance.save(on: db)
    }
    
    func asPublic() throws -> Public {
        Public(
            id: try requireID(),
            name: name,
            amount: amount,
            currency: currency,
            type: type,
            periodicity: periodicity,
            startDate: startDate)
    }
    
}

extension Cost {
    struct Create: Content {
        var name: String
        var amount: Double
        var currency: Currency
        var type: CostType
        var periodicity: Periodicity
        var startDate: Date
        
        func createModel() -> Cost {
            let cost = Cost()
            cost.name = name
            cost.amount = amount
            cost.currency = currency
            cost.type = type
            cost.periodicity = periodicity
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
        var periodicity: Periodicity
        var startDate: Date
    }
}

extension Cost.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("amount", as: Double.self, is: .range(0...))
        validations.add("currency", as: Currency.self)
        validations.add("type", as: Cost.CostType.self)
        validations.add("periodicity", as: Cost.Periodicity.self)
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
}
