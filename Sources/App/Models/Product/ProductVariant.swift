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
    
    func asPublic() throws -> Public {
        Public(
            id: try requireID(),
            name: name,
            price: price,
            salePrice: salePrice,
            sku: sku,
            stock: stock,
            product: try product.requireID())
    }
}

extension ProductVariant {
    struct Create: Validatable {
        var name: String
        var price: Double
        var salePrice: Double
        var sku: String? = nil
        var stock: Int? = nil
        var product: Product.IDValue
        
        var model: ProductVariant {
            let model = ProductVariant()
            model.name = name
            model.price = price
            model.salePrice = salePrice
            model.sku = sku
            model.stock = stock
            model.$product.id = product
            return model
        }
        
        static func validations(_ validations: inout Validations) {
            validations.add("name", as: String.self, is: !.empty)
            validations.add("price", as: Double.self, is: .valid)
            validations.add("salePrice", as: Double.self, is: .valid)
            validations.add("sku", as: String?.self, required: false)
            validations.add("stock", as: Int?.self, required: false)
            validations.add("product", as: UUID.self, is: .valid)
        }
    }
    
    struct Public: Content {
        var id: UUID?
        var name: String
        var price: Double
        var salePrice: Double
        var sku: String?
        var stock: Int?
        var product: Product.IDValue
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
