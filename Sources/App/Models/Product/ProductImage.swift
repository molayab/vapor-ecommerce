import Fluent
import Vapor
import SwiftGD

struct UploadImage: Content {
    var ext: String
    var dat: Data
}

final class ProductImage: Model {
    static let schema = "product_images"
    static let allowedExtensions = ["jpg", "jpeg", "png", "gif"]
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "url")
    var url: String
    
    @Parent(key: "variant_id")
    var variant: ProductVariant

    private static func storeImageVariant(_ image: Image, _ publicFolder: String, _ fileName: String, size: Int) throws {
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
        
        let parentId = try variant.requireID()
        let publicFolder = request.application.directory.publicDirectory
        + "images/catalog/" + parentId.uuidString + "/"
        
        let fileManager = FileManager.default
        let fileName = UUID().uuidString + "." + image.ext
        let filePath = publicFolder + fileName

        guard fileManager.fileExists(atPath: publicFolder) else {
            try fileManager.createDirectory(atPath: publicFolder, withIntermediateDirectories: true)
            return try await upload(image: image, forVariant: variant, on: request)
        }
        guard allowedExtensions.contains(image.ext) else {
            throw Abort(.badRequest)
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            let image = try Image(data: image.dat)

            group.addTask {
                try storeImageVariant(image, publicFolder, fileName, size: 256)
            }
            
            group.addTask {
                try storeImageVariant(image, publicFolder, fileName, size: 512)
            }
            
            group.addTask {
                try storeImageVariant(image, publicFolder, fileName, size: 1024)
            }

            try await group.waitForAll()
        }
        
        guard fileManager.createFile(atPath: filePath, contents: image.dat) else {
            throw Abort(.internalServerError)
        }

        let model = ProductImage()
        model.url = fileName
        model.$variant.id = try variant.requireID()
            
        try await model.save(on: request.db)
        return model
    }
    
    func deleteImage(on request: Request) async throws {
        // Delete the variant's images in its folder
        // the simple way is to remove the folder itself
        let id = try await self.$variant.get(on: request.db).requireID().uuidString
        let publicFolder = request.application.directory.publicDirectory
        + "images/catalog/" + id + "/"
        
        let fileManager = FileManager.default
        try? fileManager.removeItem(atPath: publicFolder)
        
        // Delete the image from the database
        try await self.delete(on: request.db)
    }
}

extension ProductImage {
    struct Create: Validatable {
        var url: String
        var variant: ProductVariant.IDValue
        var model: ProductImage {
            let model = ProductImage()
            model.url = url
            model.$variant.id = variant
            return model
        }
        
        static func validations(_ validations: inout Validations) {
            validations.add("url", as: String.self, is: !.empty)
            validations.add("product", as: UUID.self, is: .valid)
        }
    }
}

extension ProductImage {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(ProductImage.schema)
                .id()
                .field("url", .string, .required)
                .field("variant_id", .uuid, .required, .references(ProductVariant.schema, "id"))
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(ProductImage.schema).delete()
        }
    }
}
