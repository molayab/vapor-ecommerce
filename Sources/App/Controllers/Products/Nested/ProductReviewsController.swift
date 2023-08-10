import Fluent
import Vapor

struct ProductReviewsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let root = routes.grouped("products", ":productId", "reviews")
        
        // Public API
        root.get(use: listReviews)
        
        // Private API
        
        let authRequired = root.grouped([
            UserSessionAuthenticator(),
            User.guardMiddleware()
        ])
        
        authRequired.post(use: addReview)
        authRequired.delete(":reviewId", use: deleteReview)
        authRequired.patch(":reviewId", use: editReview)
    }
    
    /// Private API
    /// DELETE /products/:productId/reviews/:reviewId
    /// This endpoint is used to delete a review.
    /// Only the review's author or a moderator can delete a review.
    private func deleteReview(req: Request) async throws -> HTTPStatus {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let reviewId = req.parameters.get("reviewId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let product = try await Product.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let user = try req.auth.require(User.self)
        guard let review = try await product
            .$reviews
            .query(on: req.db)
            .filter(\.$id == reviewId)
            .first() else {
            
            throw Abort(.notFound)
        }
        
        let isModerator = try await user.isReviewModerator(on: req.db)
        guard try review.$user.id == user.requireID() || isModerator else {
            throw Abort(.forbidden)
        }
        
        try await review.delete(on: req.db)
        return .ok
    }
    
    /// Private API
    /// PATCH /products/:productId/reviews/:reviewId
    /// This endpoint is used to edit a review.
    /// Only the review's author or a moderator can edit a review.
    private func editReview(req: Request) async throws -> ProductReview.Public {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let reviewId = req.parameters.get("reviewId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let product = try await Product.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let user = try req.auth.require(User.self)
        guard let review = try await product
            .$reviews
            .query(on: req.db)
            .filter(\.$id == reviewId)
            .first() else {
            
            throw Abort(.notFound)
        }
        
        let isModerator = try await user.isReviewModerator(on: req.db)
        guard try review.$user.id == user.requireID() || isModerator else {
            throw Abort(.forbidden)
        }
        
        let payload = try req.content.decode(ProductReview.Create.self)
        try ProductReview.Create.validate(content: req)
        
        review.comment = payload.comment
        review.score = payload.score
        
        try await review.update(on: req.db)
        return try review.asPublic()
    }
    
    /// Public API
    /// GET /products/:productId/reviews
    /// This endpoint is used to list all reviews for a product.
    private func listReviews(req: Request) async throws -> [ProductReview.Public] {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let product = try await Product.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try await product.$reviews.get(on: req.db).map { try $0.asPublic() }
    }
    
    /// Private API
    /// POST /products/:productId/reviews
    /// This endpoint is used to add a review for a product.
    private func addReview(req: Request) async throws -> ProductReview.Public {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let product = try await Product.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let payload = try req.content.decode(ProductReview.Create.self)
        try ProductReview.Create.validate(content: req)
        let review = try await payload.create(for: req, product: product)
        return try review.asPublic()
    }
    
}
