import Fluent
import Vapor

final class ProductReview: Model {
    static let schema = "product_reviews"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "comment")
    var comment: String?
    
    @Field(key "score")
    var score: Int
    
    @Parent(key: "product_id")
    var product: Product
    
    @Parent(key: "user_id")
    var user: User
    
    func asPublic() throws -> Public {
        Public(
            id: try requireID(),
            comment: comment,
            score: score,
            product: try product.asPublic(),
            user: try user.asPublic()
        )
    }
}

extension ProductReview {
    struct Create: Validatable {
        var comment: String?
        var score: Int
        var product: Product.IDValue
        var user: User.IDValue
        
        var model: ProductReview {
            let model = ProductReview()
            model.comment = comment
            model.score = score
            model.$product.id = product
            model.$user.id = user
            return model
        }
        
        static func validations(_ validations: inout Validations) {
            validations.add("comment", as: String?.self, is: nil? || (!.empty && .count(5...256)))
            validations.add("score", as: Int.self, is: .range(1...5))
            validations.add("product", as: UUID.self, is: .valid)
            validations.add("user", as: UUID.self, is: .valid)
        }
    }
    
    struct Public: Content {
        var id: UUID?
        var comment: String?
        var score: Int
        var product: Product.Public
        var user: User.Public
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
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema("product_reviews").delete()
        }
    }
}
