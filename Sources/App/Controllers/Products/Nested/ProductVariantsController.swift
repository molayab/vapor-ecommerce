import Fluent
import Vapor

struct ProductVariantsController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        let products = routes.grouped("products", ":productId", "variants")
        
        // Public API
        products.get(use: listVariants)
        products.get(":variantId", use: getVariant)
        
        // Restricted API
        let restricted = products.grouped([
            UserSessionAuthenticator(),
            User.guardMiddleware(),
            RoleMiddleware(roles: [.admin, .manager])
        ])
        
        restricted.post(use: createVariant)
        restricted.delete(":variantId", use: deleteVariant)
        restricted.patch(":variantId", use: editVariant)
        restricted.get("sku", use: generateSku)
    }
    
    private func getVariant(req: Request) async throws -> ProductVariant.Public {
        guard let variantId = req.parameters.get("variantId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let variant = try await ProductVariant.find(variantId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try await variant.asPublic(on: req.db)
    }
    
    /// Restricted API
    /// GET /products/sku/generate
    /// This is a helper function to generate a unique SKU for a variant.
    private func generateSku(req: Request) async throws -> [String: String] {
        let sku = "SKU" + String(UUID().uuidString.prefix(8))
        
        guard try await ProductVariant.query(on: req.db).filter(\.$sku == sku).first() == nil else {
            return try await generateSku(req: req)
        }
        
        return ["sku": sku]
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
            .asyncMap({ try await $0.asPublic(on: req.db) })
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
    private func deleteVariant(req: Request) async throws -> [String: String] {
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
        
        do {
            let fm = FileManager.default
            let path = try req.application.directory.publicDirectory
                + "images/catalog/\(product.requireID().uuidString)/\(variant.requireID().uuidString)"
            try fm.removeItem(atPath: path)
        } catch {
            req.logger.error("Error deleting variant image: \(error.localizedDescription)")
        }
        
        try await variant.delete(on: req.db)
        return [
            "status": "success",
            "message": "Variant deleted successfully."
        ]
    }
}
