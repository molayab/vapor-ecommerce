import Vapor
import Fluent

final class ProductAnswer: Model {
    static let schema = "product_answers"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "answer")
    var answer: String
    
    @Parent(key: "question_id")
    var question: ProductQuestion
    
    @Parent(key: "user_id")
    var user: User
}

extension ProductAnswer {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async {
            try await database.schema(ProductAnswer.schema)
                .id()
                .field("answer", .string, .required)
                .field("question_id", .uuid, .required, .references(ProductQuestion.schema, "id"))
                .field("user_id", .uuid, .required, .references(User.schema, "id"))
                .create()
        }
        
        func rollback(on database: Database) async {
            try await database.schema(ProductAnswer.schema).delete()
        }
    }
}
