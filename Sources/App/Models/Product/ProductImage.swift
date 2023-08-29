import Fluent
import Vapor
import SwiftGD
import Queues
import Foundation

struct ProductImage: Codable {
    static let schema = "product_images"
    static let allowedExtensions = ["jpg", "jpeg", "png"]

    struct UploadImage: Content {
        var size: Int
        var name: String
        var ext: String
        var dat: Data
    }

    static func storeImageVariant(_ image: Image, _ publicFolder: String, _ fileName: String, size: Int, app: Application) throws {
        guard let thumbnail = image.resizedTo(width: size) else {
            throw Abort(.internalServerError)
        }

        let path = publicFolder + "t\(size)_" + fileName
        let data = try thumbnail.export(as: .jpg(quality: 80))

        guard FileManager.default.createFile(atPath: path, contents: data) else {
            throw Abort(.notAcceptable)
        }
    }

    @discardableResult
    static func upload(image: UploadImage,
                       forVariant variant: ProductVariant,
                       on request: Request) async throws -> ProductImage {

        guard let ext = image.ext.split(separator: "/").last else {
            throw Abort(.badRequest)
        }
        guard allowedExtensions.contains(String(ext)) else {
            throw Abort(.badRequest)
        }

        try await request.queue.dispatch(ImageResizerJob.self, .init(
            image: image,
            parentId: variant.$product.$id.wrappedValue,
            id: try variant.requireID()))

        return ProductImage()
    }
}
