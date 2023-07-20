import Vapor
import Fluent


/**
    # Product Model
    This model is used to store the product's information.
 
    ## Properties
    - `id`: UUID
    - `title`: String
    - `description`: String
    - `price`: Double
    - `salePrice`: Double
    - `isAvailable`: Bool
    - `createdAt`: Date
    - `updatedAt`: Date
    - `creator`: User
    - `editor`: User
    - `category`: Category
 
 */
final class Product: Model {
    static let schema = "products"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "price")
    var price: Double
    
    @Field(key: "salePrice")
    var salePrice: Double
    
    @Field(key: "isAvailable")
    var isAvailable: Bool
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?
    
    @Parent(key: "creator_user_id")
    var creator: User
    
    @OptionalParent(key: "editor_user_id")
    var editor: User?
    
    @Parent(key: "category_id")
    var category: Category
    
    
    init() { }
    init(model: Create) {
        self.title = model.title
        self.description = model.description
        self.price = model.price
        self.isAvailable = model.isAvailable
        self.category = model.category
        self.creator = model.creator
    }
    
    func asPublic(on database: Database) async throws -> Public {
        Public(
            id: try requireID(),
            title: title,
            description: description,
            price: price,
            salePrice: salePrice,
            isAvailable: isAvailable,
            createdAt: createdAt,
            updatedAt: updatedAt,
            creator: try await creator.asPublic(on: database),
            editor: try await editor?.asPublic(on: database),
            category: try category.asPublic())
    }

}

extension Product {
    struct Create: Content {
        var title: String
        var description: String
        var price: Double
        var isAvailable: Bool
        var creator: User
        var category: Category
    }
    
    struct Public: Content {
        var id: UUID?
        var title: String
        var description: String
        var price: Double
        var salePrice: Double
        var isAvailable: Bool
        var createdAt: Date?
        var updatedAt: Date?
        var creator: User.Public
        var editor: User.Public?
        var category: Category.Public
    }
    
}

extension Product.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, is: !.empty)
        validations.add("description", as: String.self, is: !.empty)
        validations.add("price", as: Double.self, is: .range(0...))
    }
}

extension Product {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema("products")
                .id()
                .field("title", .string, .required)
                .field("description", .string, .required)
                .field("price", .double, .required)
                .field("salePrice", .double, .required)
                .field("isAvailable", .bool, .required)
                .field("creator_user_id", .uuid, .required, .references("users", "id"))
                .field("editor_user_id", .uuid, .references("users", "id"))
                .field("category_id", .uuid, .required, .references("categories", "id"))
                .field("createdAt", .datetime)
                .field("updatedAt", .datetime)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema("products").delete()
        }
    }

}
