import Fluent
import Vapor

struct ProductVariantsController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        let products = routes.grouped("products", ":productId", "variants")
        
        // Public API
        products.get(use: listVariants)
        
        // Restricted API
        let restricted = products.grouped([
            UserSessionAuthenticator(),
            User.guardMiddleware(),
            RoleMiddleware(roles: [.admin, .manager])
        ])
        
        restricted.post(use: createVariant)
        restricted.delete(":variantId", use: deleteVariant)
        restricted.patch(":variantId", use: editVariant)
    }
    
    /// Public API
    /// GET /products/:productId/variants
    /// This endpoint is used to retrieve all variants for a product.
    private func listVariants(req: Request) async throws -> [ProductVariant.Public] {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let product = try await Product.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try await product.$variants
            .query(on: req.db)
            .all()
            .asyncMap({ variant in
                try await variant.asPublic(on: req.db)
        })
    }
    
    /// Restricted API
    /// PATCH /products/:productId/variants
    /// This endpoint is used to edit a variant.
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
    
    /// Restricted API
    /// POST /products/:productId/variants
    /// This endpoint is used to create a variant.
    private func createVariant(req: Request) async throws -> ProductVariant.Public {
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
    
    /// Restricted API
    /// DELETE /products/:productId/variants/:variantId
    /// This endpoint is used to delete a variant.
    private func deleteVariant(req: Request) async throws -> Response {
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
