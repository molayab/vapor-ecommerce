import Fluent
import Vapor

struct ProductVariantDeleteModel: Content {
    let status: String
    let wasProductDeleted: Bool
}

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
    
    private func delete(req: Request) async throws -> ProductVariantDeleteModel {
        guard let uuid = req.parameters.get("variantId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let variant = try await ProductVariant.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }
        
        // Products MUST NOT have empty variants
        // If it is the last variant, delete the product
        let product = try await variant.$product.get(on: req.db)
        let variants = try await product.$variants.get(on: req.db)
        for image in try await variant.$images.get(on: req.db) {
            try await image.delete(on: req.db)
        }
        
        if variants.count <= 1 {
            try await variant.delete(on: req.db)
            try await variant.product.delete(on: req.db)
            return ProductVariantDeleteModel(
                status: "deleted",
                wasProductDeleted: true
            )
        } else {
            try await variant.delete(on: req.db)
            return ProductVariantDeleteModel(
                status: "deleted",
                wasProductDeleted: false
            )
        }
    }
}
