import Vapor
import Fluent
import SwiftGD
import Queues
import NIO
import Foundation

/// A job that resizes an image and saves it to disk
struct ImageResizerJob: AsyncJob {
    /// The payload of the job
    struct Payload: Codable {
        let image: ProductImage.UploadImage
        /// The parent ID of the image a.k.a. the product ID
        let parentId: UUID
        /// The ID of the image a.k.a. the variant ID
        let id: UUID
    }

    func dequeue(_ context: QueueContext, _ payload: Payload) async throws {
        guard let ext = payload.image.ext.split(separator: "/").last else {
            context.logger.error(" !!! Could not get extension from: \(payload.image.ext)")
            throw Abort(.badRequest)
        }

        let publicFolder = context.application.directory.publicDirectory
            + "images/catalog/" + payload.parentId.uuidString + "/" + payload.id.uuidString + "/"
        let fileName = UUID().uuidString + "." + ext
        let filePath = publicFolder + fileName

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: publicFolder) else {
            await context.application.notifyMessage(" Se ha creado la carpeta \(publicFolder)")
            try fileManager.createDirectory(atPath: publicFolder, withIntermediateDirectories: true)
            return try await dequeue(context, payload)
        }
        guard fileManager.createFile(atPath: filePath, contents: payload.image.dat) else {
            await context.application.notifyMessage(" La imagen \(fileName) no ha podido ser subida")
            throw Abort(.notAcceptable)
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            let image = try Image(data: payload.image.dat)

            group.addTask {
                try ProductImage.storeImageVariant(image, publicFolder, fileName, size: 256, app: context.application)
            }

            group.addTask {
                try ProductImage.storeImageVariant(image, publicFolder, fileName, size: 512, app: context.application)
            }

            group.addTask {
                try ProductImage.storeImageVariant(image, publicFolder, fileName, size: 1024, app: context.application)
            }

            try await group.waitForAll()
        }
    }

    func error(_ context: QueueContext, _ error: Error, _ payload: Payload) async throws {
        context.logger.error("Error resizing image: \(error) for payload: \(payload)")
    }
}
