import Fluent
import Vapor

final class ProductReview: Model {
    static let schema = "product_reviews"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "comment")
    var comment: String?

    @Field(key: "score")
    var score: Int

    @Parent(key: "product_id")
    var product: Product

    @Parent(key: "user_id")
    var user: User

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    func asPublic() throws -> Public {
        Public(
            id: try requireID(),
            comment: comment,
            score: score
        )
    }
}

extension ProductReview {
    struct Create: Validatable, Content {
        var comment: String?
        var score: Int

        var model: ProductReview {
            let model = ProductReview()
            model.comment = comment
            model.score = score
            return model
        }

        @discardableResult
        func create(for req: Request, product: Product) async throws -> ProductReview {
            let model = self.model
            model.$product.id = try product.requireID()
            model.$user.id = try req.auth.require(User.self).requireID()
            try await model.save(on: req.db)
            return model
        }

        static func validations(_ validations: inout Validations) {
            validations.add("comment", as: String?.self, is: .nil || (!.empty && .count(5...256)))
            validations.add("score", as: Int.self, is: .range(1...5))
        }
    }

    struct Public: Content {
        var id: UUID?
        var comment: String?
        var score: Int
        var createdAt: Date?
    }
}

extension ProductReview {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema("product_reviews")
                .id()
                .field("comment", .string)
                .field("score", .int, .required)
                .field("product_id", .uuid, .required, .references("products", "id"))
                .field("user_id", .uuid, .required, .references("users", "id"))
                .field("created_at", .datetime)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("product_reviews").delete()
        }
    }
}
