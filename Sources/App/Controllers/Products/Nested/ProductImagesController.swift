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

        return try await variant.asPublic(request: req).images
    }

    private func createImages(req: Request) async throws -> [String: String] {
        guard let variantId = req.parameters.get("variantId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let variant = try await ProductVariant.find(variantId, on: req.db) else {
            throw Abort(.notFound)
        }

        let images = try req.content.decode([ProductImage.UploadImage].self)
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

        let image = try req.content.decode(ProductImage.UploadImage.self)
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

        let entries = try await req.application.fileio.listDirectory(
            path: publicPath,
            eventLoop: req.eventLoop.next()).get()
        for entry in entries {
            guard entry.name.contains(fileId) else { continue }

            let path = publicPath + "/" + entry.name
            try await req.application.fileio.remove(
                path: path,
                eventLoop: req.eventLoop.next()).get()
        }

        return ["status": "success"]
    }
}
