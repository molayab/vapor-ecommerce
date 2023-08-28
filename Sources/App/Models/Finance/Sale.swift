import Vapor
import Fluent

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
