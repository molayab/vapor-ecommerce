import Fluent
import Vapor

final class ProductImage: Model {
    static let schema = "product_images"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "url")
    var url: String
    
    @Parent(key: "variant_id")
    var variant: ProductVariant
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
            validations.add("product", as: UUID.self, is: .uuid)
        }
    }
}

extension ProductImage {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async {
            try await database.schema(ProductImage.schema)
                .id()
                .field("url", .string, .required)
                .field("variant_id", .uuid, .required, .references(ProductVariant.schema, "id"))
                .create()
        }
        
        func rollback(on database: Database) async {
            try await database.schema(ProductImage.schema).delete()
        }
    }
}
