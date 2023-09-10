import Fluent
import Vapor

struct ProductVariantsController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        let products = routes.grouped("products", ":productId", "variants")

        // Public API
        routes.get("products", "variants", use: listAllVariants)
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

        return try await variant.asPublic(request: req)
    }

    /// Restricted API
    /// GET /products/sku/generate
    /// This is a helper function to generate a unique SKU for a variant.
    private func generateSku(req: Request) async throws -> [String: String] {
        return try await generateSku(req: req, tries: 0)
    }

    private func generateSku(req: Request, tries: Int) async throws -> [String: String] {
        // Get the last created variant
        guard let variant = try await ProductVariant.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .first() else {
                return ["sku": "SKU" + String(UUID().uuidString.prefix(8))]
        }

        // Generate a new SKU by adding 1 to the last variant's SKU
        // SKU has a prefix of "SKU" and a suffix of 8 characters
        let intSku = Int((variant.sku ?? "").suffix(8)) ?? 0
        let newSku = intSku + 1

        // Add zeros to the front of the new SKU if it is less than 8 characters
        let prefix = String(repeating: "0", count: 8 - String(newSku).count)
        let sku = "SKU" + prefix + String(newSku)
        
        // Check if the new SKU is unique, if not, try again
        guard try await ProductVariant.query(on: req.db).filter(\.$sku == sku).first() == nil else {
            guard tries < 10 else {
                throw Abort(.internalServerError, reason: "Unable to generate a unique SKU.")
            }
            return try await generateSku(req: req, tries: tries + 1)
        }

        return ["sku": sku]
    }

    /// Public API
    /// GET /products/variants
    /// This endpoint is used to retrieve all variants.
    private func listAllVariants(req: Request) async throws -> Page<ProductVariant.Public> {
        let variants = try await ProductVariant.query(on: req.db)
            .join(Product.self, on: \ProductVariant.$product.$id == \Product.$id)
            .join(Category.self, on: \Category.$id == \Product.$category.$id)
            .paginate(for: req)

        return Page(
            items: try await variants.items.asyncMap { variant in
                return try await variant.asPublic(request: req)
            }, 
            metadata: .init(
                page: variants.metadata.page, 
                per: variants.metadata.per, 
                total: variants.metadata.total))
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
            .asyncMap({ try await $0.asPublic(request: req) })
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
        variant.tax = payload.tax
        variant.shippingCost = payload.shippingCost

        try await variant.save(on: req.db)
        return try await variant.asPublic(request: req)
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

        // Check sku is unique
        let sku = try req.content.get(String.self, at: "sku")
        guard try await ProductVariant.query(on: req.db).filter(\.$sku == sku).first() == nil else {
            await req.notifyMessage("El SKU ya ha sido asignado a otra variante.")
            throw Abort(.badRequest, reason: "El SKU ya ha sido asignado a otra variante.")
        }

        let payload = try req.content.decode(ProductVariant.Create.self)
        try ProductVariant.Create.validate(content: req)

        let variant = try await payload.create(for: req, product: product)
        await req.notifyMessage("Variante creada correctamente.")
        return try await variant.asPublic(request: req)
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

        let path = try req.application.directory.publicDirectory
            + "images/catalog/\(product.requireID().uuidString)/\(variant.requireID().uuidString)"

        do {
            for entry in try await req.application.fileio.listDirectory(
                path: path,
                eventLoop: req.eventLoop.next()).get() {
                    
                do {
                    try await req.application.fileio.remove(
                        path: path + "/" + entry.name,
                        eventLoop: req.eventLoop.next()).get()
                } catch {
                    req.logger.error("Error deleting variant image: \(error.localizedDescription)")
                }
            }
        } catch {
            req.logger.error("Error deleting variant image: \(error.localizedDescription)")
        }
        
        try await variant.delete(on: req.db)
        await req.notifyMessage("Variante ha sido eliminada correctamente.")
        return [
            "status": "success",
            "message": "Variant deleted successfully."
        ]
    }
}
