import Vapor
import Fluent

struct ProductQuestionsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped("products", ":productId", "questions")

        // Public API
        routes.get(use: listQuestions)

        // Private API
        let protected = routes.grouped(
            UserSessionAuthenticator(),
            User.guardMiddleware())
        protected.post(use: create)
        protected.delete(":questionId", use: delete)
        protected.patch(":questionId", use: edit)
    }

    /// Public API
    /// GET /products/:productId/questions
    /// Returns paginated questions
    func listQuestions(req: Request) async throws -> Page<ProductQuestion> {
        guard let productId = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        return try await ProductQuestion.query(on: req.db)
            .filter(\.$product.$id == productId)
            .paginate(for: req)
    }

    /// Private API
    /// POST /products/:productId/questions
    /// Creates a new question
    func create(req: Request) async throws -> ProductQuestion.Public {
        guard let productId = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        try ProductQuestion.Create.validate(content: req)
        let user = try req.auth.require(User.self)
        guard let product = try await Product.find(productId, on: req.db) else {
            throw Abort(.notFound)
        }

        let payload = try req.content.decode(ProductQuestion.Create.self)
        let question = payload.model
        question.product = product
        question.user = user

        try await question.save(on: req.db)
        return try await question.asPublic(on: req)
    }

    /// Private API
    /// DELETE /products/:productId/questions/:questionId
    /// Deletes a question
    func delete(req: Request) async throws -> Response {
        guard let questionId = req.parameters.get("questionId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let question = try await ProductQuestion.find(questionId, on: req.db) else {
            throw Abort(.notFound)
        }

        let user = try req.auth.require(User.self)
        let isModerator = try await user.isReviewModerator(on: req.db)
        guard question.user.id == user.id || isModerator else {
            throw Abort(.forbidden)
        }

        try await question.delete(on: req.db)
        return Response(status: .ok)
    }

    /// Private API
    /// PATCH /products/:productId/questions/:questionId
    /// Edits a question (only question text)
    func edit(req: Request) async throws -> ProductQuestion.Public {
        guard let questionId = req.parameters.get("questionId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let question = try await ProductQuestion.find(questionId, on: req.db) else {
            throw Abort(.notFound)
        }

        let user = try req.auth.require(User.self)
        let isModerator = try await user.isReviewModerator(on: req.db)
        guard question.user.id == user.id || isModerator else {
            throw Abort(.forbidden)
        }

        try ProductQuestion.Create.validate(content: req)
        let payload = try req.content.decode(ProductQuestion.Create.self)
        question.question = payload.question
        try await question.save(on: req.db)
        return try await question.asPublic(on: req)
    }
}
