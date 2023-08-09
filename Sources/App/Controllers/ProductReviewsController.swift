import Fluent
import Vapor

struct ProductReviewsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let root = routes.grouped("products", ":productId", "reviews")
        let restricted = root.grouped([
            UserSessionAuthenticator(),
            User.guardMiddleware()
        ])
        
        restricted.post(use: addReview)
        restricted.get(use: listReviews)
        restricted.delete(":reviewId", use: deleteReview)
        restricted.patch(":reviewId", use: editReview)
    }
    
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
        
        guard try review.$user.id == user.requireID() else {
            throw Abort(.forbidden)
        }
        
        try await review.delete(on: req.db)
        return .ok
    }
    
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
        
        guard try review.$user.id == user.requireID() else {
            throw Abort(.forbidden)
        }
        
        let payload = try req.content.decode(ProductReview.Create.self)
        try ProductReview.Create.validate(content: req)
        
        review.comment = payload.comment
        review.score = payload.score
        
        try await review.update(on: req.db)
        return try review.asPublic()
    }
    
    private func listReviews(req: Request) async throws -> [ProductReview.Public] {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        guard let product = try await Product.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try await product.$reviews.get(on: req.db).map { try $0.asPublic() }
    }
    
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
