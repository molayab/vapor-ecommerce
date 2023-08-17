import Vapor
import Fluent

struct ProductImagesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let images = routes.grouped("products", ":productId", "variants", ":variantId", "images")
        // Public API
        images.get(use: getAllImages)
        
        // Restricted API
        let restricted = images.grouped([
            UserSessionAuthenticator(),
            User.guardMiddleware(),
            RoleMiddleware(roles: [.admin, .manager])
        ])
        
        restricted.post(use: createImage)
        restricted.post("multiple", use: createImages)
        restricted.delete(use: deleteImage)
    }
    
    private func getAllImages(req: Request) async throws -> [String] {
        guard let variantId = req.parameters.get("variantId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let variant = try await ProductVariant.find(variantId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try variant.asPublic().images
    }
    
    private func createImages(req: Request) async throws -> [String: String] {
        guard let variantId = req.parameters.get("variantId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let variant = try await ProductVariant.find(variantId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let images = try req.content.decode([UploadImage].self)
        for image in images {
            try await ProductImage.upload(image: image, forVariant: variant, on: req)
        }
        
        return ["status": "success"]
    }
    
    private func createImage(req: Request) async throws -> [String: String] {
        guard let variantId = req.parameters.get("variantId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let variant = try await ProductVariant.find(variantId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let image = try req.content.decode(UploadImage.self)
        try await ProductImage.upload(image: image, forVariant: variant, on: req)

        return ["status": "success"]
    }
    
    /// Restricted API
    /// DELETE /products/:productId/variants/:variantId/images
    /// This endpoint is used to delete an image for a variant.
    private func deleteImage(req: Request) async throws -> [String: String] {
        guard let variantId = req.parameters.get("variantId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let variant = try await ProductVariant.find(variantId, on: req.db) else {
            throw Abort(.notFound)
        }
        guard let content = req.body.string else {
            throw Abort(.badRequest)
        }
        guard try content.contains(variant.requireID().uuidString) else {
            throw Abort(.badRequest)
        }
        
        let fm = FileManager.default
        let publicPath = try req.application.directory.publicDirectory
            + "/images/catalog/"
            + variant.$product.$id.wrappedValue.uuidString + "/"
            + variant.requireID().uuidString

        guard let fileId = content.split(separator: "/").last?
            .replacingOccurrences(of: "t256_", with: "")
            .replacingOccurrences(of: "t512_", with: "")
            .replacingOccurrences(of: "t1024_", with: "") else {
            throw Abort(.badRequest)
        }
        
        do {
            try fm.enumerator(atPath: publicPath)?.forEach { file in
                guard let file = file as? String else { return }
                guard file.contains(fileId) else { return }
                
                let path = publicPath + "/" + file
                try fm.removeItem(atPath: path)
            }
        } catch {
            req.logger.error("\(error.localizedDescription)")
            throw Abort(.internalServerError)
        }
        
        return ["status": "success"]
    }
}
