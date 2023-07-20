import Vapor

struct ProductsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.group(Auth.authenticator(), EnsureAdminUserMiddleware()) { protected in
            let products = protected.grouped("products")
            products.post(use: create)
            products.delete(":productId", use: delete)
        }
    }
    
    func create(req: Request) async throws -> Product.Public {
        let input = try req.content.decode(Product.Create.self)
        let product = Product(model: input)
        
        try await product.save(on: req.db)
        return try await product.asPublic(on: req.db)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let product = try await Product.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await product.delete(on: req.db)
        return .ok
    }
}

