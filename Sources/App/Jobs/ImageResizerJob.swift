import Vapor
import Fluent
import SwiftGD
import Queues

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
            throw Abort(.badRequest)
        }

        let publicFolder = context.application.directory.publicDirectory
            + "images/catalog/" + payload.parentId.uuidString + "/" + payload.id.uuidString + "/"
        let fileName = UUID().uuidString + "." + ext
        let filePath = publicFolder + fileName

        // Write to disk the original image

        do {
            try await context.application.fileio.createDirectory(path: publicFolder, mode: 0644, eventLoop: context.eventLoop.next()).get()
        } catch {
            context.logger.error("Error creating directory: \(error)")
        }

        try await context.application.fileio.write(
            fileHandle: .init(path: filePath),
            buffer: ByteBuffer(data: payload.image.dat),
            eventLoop: context.eventLoop.next()).get()

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
