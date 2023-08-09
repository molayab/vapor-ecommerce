import Fluent
import Vapor

struct ProductsVariantsController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        let products = routes.grouped("products")
        let restricted = products.grouped([
            UserSessionAuthenticator(),
            User.guardMiddleware(),
            RoleMiddleware(roles: [.admin, .manager])
        ])
        
        restricted.post(":productId", "variants", use: create)
        restricted.delete(":productId", "variants", ":variantId", use: delete)
        restricted.patch(":productId", "variants", ":variantId", use: editVariant)
    }
    
    private func editVariant(req: Request) async throws -> ProductVariant.Public {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let variantId = req.parameters.get("variantId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let product = try await Product.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let user = try req.auth.require(User.self)
        let payload = try req.content.decode(ProductVariant.Create.self)
        try ProductVariant.Create.validate(content: req)
        
        guard let variant = try await product
            .$variants
            .query(on: req.db)
            .filter(\.$id == variantId).first() else {
                throw Abort(.notFound)
        }
        
        variant.name = payload.name
        variant.price = payload.price
        variant.salePrice = payload.salePrice
        variant.sku = payload.sku
        variant.stock = payload.stock
        variant.isAvailable = payload.availability
        
        try await variant.save(on: req.db)
        return try await variant.asPublic(on: req.db)
    }
    
    private func create(req: Request) async throws -> ProductVariant.Public {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let product = try await Product.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let payload = try req.content.decode(ProductVariant.Create.self)
        try ProductVariant.Create.validate(content: req)
        
        let variant = try await payload.create(for: req, product: product)
        return try await variant.asPublic(on: req.db)
    }
    
    private func delete(req: Request) async throws -> Response {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let variantId = req.parameters.get("variantId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let product = try await Product.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }
        
        guard let variant = try await product
            .$variants
            .query(on: req.db)
            .filter(\.$id == variantId).first() else {
                throw Abort(.notFound)
        }
        
        try await variant.delete(on: req.db)
        return Response(status: .ok)
    }
}
