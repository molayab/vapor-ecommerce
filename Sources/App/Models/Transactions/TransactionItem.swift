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


    @Parent(key: "transaction_id")
    var transaction: Transaction

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    func asPublic(request: Request) async throws -> Public {
        try await $productVariant.load(on: request.db)
        return try Public(
            id: requireID(),
            quantity: quantity,
            price: price,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension TransactionItem {
    struct Public: Content {
        var id: UUID
        var quantity: Int
        var price: Double
        var createdAt: Date?
        var updatedAt: Date?
    }

    struct Create: Content {
        var quantity: Int
        var productVariantId: UUID
        var price: Double
        var tax: Double

        func create() -> TransactionItem {
            let model = TransactionItem()
            model.quantity = quantity
            model.$productVariant.id = productVariantId
            model.price = price
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
                .field("transaction_id", .uuid, .references("transactions", "id"))
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(schema).delete()
        }
    }

    struct AddTimestampsMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(schema)
                .field("created_at", .datetime, .custom("DEFAULT now()"))
                .field("updated_at", .datetime, .custom("DEFAULT now()"))
                .update()
        }

        func revert(on database: Database) async throws {
            try await database.schema(schema)
                .deleteField("created_at")
                .deleteField("updated_at")
                .update()
        }
    }
    
    struct RemoveDiscountFromTransactionItemMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(schema)
                .deleteField("discount")
                .update()
        }

        func revert(on database: Database) async throws {
            try await database.schema(schema)
                .field("discount", .double, .required)
                .update()
        }
    }
    
    struct RemoveTaxTotalAndCurrencyMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(schema)
                .deleteField("tax")
                .deleteField("total")
                .deleteField("currency")
                .update()
        }

        func revert(on database: Database) async throws {
            try await database.schema(schema)
                .field("tax", .double, .required)
                .field("total", .double, .required)
                .field("currency", .string, .required)
                .update()
        }
    }
}
