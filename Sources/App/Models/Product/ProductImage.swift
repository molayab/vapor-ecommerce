import Fluent
import Vapor
import SwiftGD
import Queues

struct UploadImage: Content {
    var size: Int
    var name: String
    var ext: String
    var dat: Data
}

struct ImageResizerJob: AsyncJob {
    struct Payload: Codable {
        let image: UploadImage
        let parentId: UUID
        let id: UUID
    }
    
    func dequeue(_ context: QueueContext, _ payload: Payload) async throws {
        let publicFolder = context.application.directory.publicDirectory
        + "images/catalog/" + payload.parentId.uuidString + "/"
        
        let fileManager = FileManager.default
        let fileName = payload.id.uuidString + ".jpeg"
        let filePath = publicFolder + fileName
        
        // Write to disk the original image
        
        guard fileManager.fileExists(atPath: publicFolder) else {
            try fileManager.createDirectory(atPath: publicFolder, withIntermediateDirectories: true)
            return try await dequeue(context, payload)
        }
        guard fileManager.createFile(atPath: filePath, contents: payload.image.dat) else {
            throw Abort(.notAcceptable)
        }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            let image = try Image(data: payload.image.dat)

            group.addTask {
                try ProductImage.storeImageVariant(image, publicFolder, fileName, size: 256)
            }
            
            group.addTask {
                try ProductImage.storeImageVariant(image, publicFolder, fileName, size: 512)
            }
            
            group.addTask {
                try ProductImage.storeImageVariant(image, publicFolder, fileName, size: 1024)
            }

            try await group.waitForAll()
        }
    }

    func error(_ context: QueueContext, _ error: Error, _ payload: Payload) async throws {
        // If you don't want to handle errors you can simply return. You can also omit this function entirely.
    }
}

struct ProductImage: Codable {
    static let schema = "product_images"
    static let allowedExtensions = ["jpg", "jpeg", "png"]

    static func storeImageVariant(_ image: Image, _ publicFolder: String, _ fileName: String, size: Int) throws {
        guard let thumbnail = image.resizedTo(width: size) else {
            throw Abort(.internalServerError)
        }

        let url = URL(fileURLWithPath: publicFolder + "thumbnail-\(size)_" + fileName)
        guard thumbnail.write(to: url) else {
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
    
    func deleteImage(on request: Request) async throws {
        // Delete the variant's images in its folder
        // the simple way is to remove the folder itself
        // let id = try await self.$variant.get(on: request.db).requireID().uuidString
        // let publicFolder = request.application.directory.publicDirectory
        // + "images/catalog/" + id + "/"
        
        // let fileManager = FileManager.default
        // try? fileManager.removeItem(atPath: publicFolder)
        
        // Delete the image from the database
        // try await self.delete(on: request.db)
    }
}

