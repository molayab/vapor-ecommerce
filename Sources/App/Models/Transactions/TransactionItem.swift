import Fluent
import Vapor

final class TransactionItem: Model {
    static var schema: String = "transaction_items"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "quantity")
    var quantity: Int
    
    @Parent(key: "product_variant_id")
    var productVariant: ProductVariant
    
    @Field(key: "price")
    var price: Double
    
    @Field(key: "discount")
    var discount: Double
    
    @Field(key: "tax")
    var tax: Double
    
    @Field(key: "total")
    var total: Double
    
    @Enum(key: "currency")
    var currency: Currency
    
    @Parent(key: "transaction_id")
    var transaction: Transaction
    
    func asPublic() throws -> Public {
        return try .init(
            id: requireID(),
            quantity: quantity,
            price: price,
            discount: discount,
            tax: tax,
            total: total
        )
    }
}

extension TransactionItem {
    struct Public: Content {
        var id: UUID
        var quantity: Int
        var price: Double
        var discount: Double
        var tax: Double
        var total: Double
    }
    
    struct Create: Content {
        var quantity: Int
        var productVariantId: UUID
        var price: Double
        var discount: Double
        var tax: Double
        
        func create() -> TransactionItem {
            let model = TransactionItem()
            model.currency = .COP
            model.quantity = quantity
            model.$productVariant.id = productVariantId
            model.price = price
            model.discount = discount
            model.tax = tax
            model.total = price + tax - discount
            return model
        }
    }
}

extension TransactionItem {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(schema)
                .id()
                .field("quantity", .int, .required)
                .field("product_variant_id", .uuid, .required, .references("product_variants", "id"))
                .field("price", .double, .required)
                .field("discount", .double, .required)
                .field("tax", .double, .required)
                .field("total", .double, .required)
                .field("currency", .string, .required)
                .field("transaction_id", .uuid, .required, .references("transactions", "id"))
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(schema).delete()
        }
    }
}
