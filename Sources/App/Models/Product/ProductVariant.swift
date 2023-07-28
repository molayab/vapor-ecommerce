import Vapor
import Fluent

final class ProductVariant: Model {
    static let schema = "product_variants"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "is_available")
    var isAvailable: Bool
    
    @Field(key: "price")
    var price: Double
    
    @Field(key: "sale_price")
    var salePrice: Double
    
    @Field(key: "sku")
    var sku: String?
    
    @Field(key: "stock")
    var stock: Int?
    
    @Parent(key: "product_id")
    var product: Product
    
    @Children(for: \.$variant)
    var images: [ProductImage]
    
    func asPublic(on database: Database) async throws -> Public {
        let images = try await self.$images.get(on: database)
        let urls = images.map { "/images/catalog/\($0.url)" }

        return Public(
            id: try requireID(),
            name: name,
            price: price,
            salePrice: salePrice,
            sku: sku,
            stock: stock,
            images: urls)
    }
}

extension ProductVariant {
    struct Create: Content, Validatable {
        var name: String
        var price: Double
        var salePrice: Double
        var sku: String?
        var stock: Int?
        var availability: Bool
        var images: [UploadImage]
        
        @discardableResult
        func create(for request: Request, product: Product) async throws -> ProductVariant {
            let model = ProductVariant()
            model.name = name
            model.price = price
            model.salePrice = salePrice
            model.sku = sku
            model.stock = stock
            model.isAvailable = availability
            model.$product.id = try product.requireID()
            try await model.create(on: request.db)
            
            // Upload images
            for image in images {
                try await ProductImage.upload(image: image, forVariant: model, on: request)
            }
            
            return model
        }
        
        static func validations(_ validations: inout Validations) {
            validations.add("name", as: String.self, is: !.empty)
            validations.add("price", as: Double.self, is: .valid)
            validations.add("salePrice", as: Double.self, is: .valid)
            validations.add("sku", as: String?.self, required: false)
            validations.add("stock", as: Int?.self, required: false)
        }
    }
    
    struct Public: Content {
        var id: UUID?
        var name: String
        var price: Double
        var salePrice: Double
        var sku: String?
        var stock: Int?
        var images: [String]
    }
}

extension ProductVariant {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema("product_variants")
                .id()
                .field("name", .string, .required)
                .field("is_available", .bool, .required)
                .field("price", .double, .required)
                .field("sale_price", .double, .required)
                .field("sku", .string)
                .field("stock", .int)
                .field("product_id", .uuid, .required, .references("products", "id"))
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema("product_variants").delete()
        }
    }
}
