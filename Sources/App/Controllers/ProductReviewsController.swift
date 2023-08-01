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
