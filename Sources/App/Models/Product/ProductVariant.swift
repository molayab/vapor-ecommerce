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
    var stock: Int
    
    @Field(key: "tax")
    var tax: Double
    
    @Field(key: "shipping_cost")
    var shippingCost: Double?
    
    @Parent(key: "product_id")
    var product: Product
    
    var isAvailableForSale: Bool {
        return isAvailable && stock > 0
    }
    
    func asPublic() throws -> Public {
        let fm = FileManager.default
        let path = DirectoryConfiguration.detect().publicDirectory
            + "/images/catalog/" + ($product.$id.wrappedValue.uuidString)
        
        let items = try fm.contentsOfDirectory(atPath: path)
        return Public(
            id: try requireID(),
            product: $product.$id.wrappedValue,
            name: name,
            price: price,
            salePrice: salePrice,
            sku: sku,
            stock: stock,
            isAvailable: isAvailable,
            images: items.map { "/images/catalog/" + ($product.$id.wrappedValue.uuidString) + "/" + $0 },
            tax: tax,
            shippingCost: shippingCost)
    }
}

extension ProductVariant {
    struct Create: Content, Validatable {
        var name: String
        var price: Double
        var salePrice: Double
        var sku: String?
        var stock: Int
        var availability: Bool
        var tax: Double
        var shippingCost: Double?
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
            model.tax = tax
            model.shippingCost = shippingCost
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
            validations.add("sku", as: String?.self, required: true)
            validations.add("stock", as: Int?.self, required: true)
            validations.add("tax", as: Double.self, is: .range(0.0...1.0))
            validations.add("shippingCost", as: Double?.self, required: false)
        }
    }
    
    struct Public: Content {
        var id: UUID?
        var product: UUID?
        var name: String
        var price: Double
        var salePrice: Double
        var sku: String?
        var stock: Int?
        var isAvailable: Bool
        var images: [String]
        var tax: Double
        var shippingCost: Double?
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
                .field("stock", .int, .required, .custom("DEFAULT 0"))
                .field("tax", .double, .required, .custom("DEFAULT 0"))
                .field("shipping_cost", .double)
                .field("product_id", .uuid, .required, .references("products", "id"))
                .unique(on: "sku")
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema("product_variants").delete()
        }
    }
}
