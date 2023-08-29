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

    func asPublic(on request: Request) async throws -> Public {
        await Public(
            id: try requireID(),
            answer: answer,
            question: try question.asPublic(on: request),
            user: try user.asPublic(on: request.db)
        )
    }
}

extension ProductAnswer {
    struct Create: Content, Validatable {
        var answer: String
        var question: ProductQuestion.IDValue
        var user: User.IDValue
        var model: ProductAnswer {
            let model = ProductAnswer()
            model.answer = answer
            model.$question.id = question
            model.$user.id = user
            return model
        }

        static func validations(_ validations: inout Validations) {
            validations.add("answer", as: String.self, is: !.empty)
            validations.add("question", as: UUID.self, is: .valid)
            validations.add("user", as: UUID.self, is: .valid)
        }
    }

    struct Public: Content {
        var id: UUID?
        var answer: String
        var question: ProductQuestion.Public
        var user: User.Public
    }
}

extension ProductAnswer {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(ProductAnswer.schema)
                .id()
                .field("answer", .string, .required)
                .field("question_id", .uuid, .required, .references(ProductQuestion.schema, "id"))
                .field("user_id", .uuid, .required, .references(User.schema, "id"))
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(ProductAnswer.schema).delete()
        }
    }
}
