import Vapor
import Fluent

/**
    # Category Model
    This model represents a category for a product. It is used to organize products.
 
    ## Properties
    - `id`: UUID
    - `title`: String
    - `description`: String
    - `createdAt`: Date
    - `updatedAt`: Date
 
    ## Relationships
    - `products`: Children
 
    ## Migrations
    - `CreateCategory`: Creates the `categories` table
 */
final class Category: Model, Content {
    static let schema = "categories"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "description")
    var description: String
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?
    
    @Children(for: \.$category)
    var products: [Product]
    
    init() { }
    init(id: UUID? = nil, title: String, description: String) {
        self.id = id
        self.title = title
        self.description = description
    }
    
    func asPublic() throws -> Public {
        Public(id: try requireID(), title: title, description: description, createdAt: createdAt, updatedAt: updatedAt)
    }
}

extension Category {
    struct Create: Content {
        var title: String
        var description: String
    }
    
    struct Public: Content {
        var id: UUID?
        var title: String
        var description: String
        var createdAt: Date?
        var updatedAt: Date?
    }
    
    convenience init(model: Create) {
        self.init()
        self.title = model.title
        self.description = model.description
    }
}

extension Category.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, is: .count(3...))
        validations.add("description", as: String.self, is: .count(3...))
    }
}

extension Category {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema("categories")
                .id()
                .field("title", .string, .required)
                .field("description", .string, .required)
                .field("createdAt", .datetime)
                .field("updatedAt", .datetime)
                .unique(on: "title")
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema("categories").delete()
        }
    }
}
