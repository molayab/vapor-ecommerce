import Vapor
import Fluent

final class ProductQuestion: Model {
    static let schema = "product_questions"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "question")
    var question: String

    @Parent(key: "product_id")
    var product: Product

    @Children(for: \.$question)
    var answers: [ProductAnswer]

    @Parent(key: "user_id")
    var user: User

    func asPublic(on db: Database) async throws -> Public {
        await Public(
            id: try requireID(),
            question: question,
            product: try product.asPublic(on: db),
            user: try user.asPublic(on: db),
            answers: try answers.asyncMap { try await $0.asPublic(on: db) }
        )
    }
}

extension ProductQuestion {
    struct Create: Content, Validatable {
        var question: String

        var model: ProductQuestion {
            let model = ProductQuestion()
            model.question = question
            return model
        }

        static func validations(_ validations: inout Validations) {
            validations.add("question", as: String.self, is: !.empty)
        }
    }

    struct Public: Content {
        var id: UUID?
        var question: String
        var product: Product.Public
        var user: User.Public
        var answers: [ProductAnswer.Public]
    }
}

extension ProductQuestion {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(ProductQuestion.schema)
                .id()
                .field("question", .string, .required)
                .field("product_id", .uuid, .required, .references(Product.schema, "id"))
                .field("user_id", .uuid, .required, .references(User.schema, "id"))
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(ProductQuestion.schema).delete()
        }
    }
}
