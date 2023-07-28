import Fluent
import Vapor
import SwiftGD

struct UploadImage: Content {
    var ext: String
    var dat: Data
}

final class ProductImage: Model {
    static let schema = "product_images"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "url")
    var url: String
    
    @Parent(key: "variant_id")
    var variant: ProductVariant
    
    @discardableResult
    static func upload(image: UploadImage,
                       forVariant variant: ProductVariant,
                       on request: Request) async throws -> ProductImage {
        let publicFolder = request.application.directory.publicDirectory + "images/catalog/"
        let fileManager = FileManager.default
        let fileName = UUID().uuidString + "." + image.ext
        let filePath = publicFolder + fileName
        let fileUrl = URL(fileURLWithPath: filePath)
        
        if fileManager.createFile(atPath: filePath, contents: image.dat) {
            let model = ProductImage()
            model.url = fileName
            model.$variant.id = try variant.requireID()

            if let thumbnail = Image(url: fileUrl)?.resizedTo(width: 256) {
                let url = URL(fileURLWithPath: publicFolder + "thumbnail-sm_" + fileName)
                thumbnail.write(to: url)
            }

            if let thumbnail = Image(url: fileUrl)?.resizedTo(width: 512) {
                let url = URL(fileURLWithPath: publicFolder + "thumbnail-md_" + fileName)
                thumbnail.write(to: url)
            }

            if let thumbnail = Image(url: fileUrl)?.resizedTo(width: 1024) {
                let url = URL(fileURLWithPath: publicFolder + "thumbnail-lg_" + fileName)
                thumbnail.write(to: url)
            }
            
            try await model.save(on: request.db)
            return model
        }
        
        throw Abort(.internalServerError)
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
