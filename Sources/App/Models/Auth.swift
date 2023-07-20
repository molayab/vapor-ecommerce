import Vapor
import Fluent

/**
    # Auth Model
    This model represents an authentication token for a user. It is used to authenticate a user for a period of time.
    The token is generated when a user logs in and is deleted when the user logs out.
 
    ## Properties
    - `id`: UUID
    - `token`: String
    - `expiresAt`: Date
    - `createdAt`: Date
    - `user`: User
 
    ## Relationships
    - `user`: Parent
 
    ## Migrations
    - `CreateAuth`: Creates the `auths` table
 */
final class Auth: Model, Content {
    static let schema = "auths"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "token")
    var token: String
    
    @Field(key: "expires_at")
    var expiresAt: Date
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Parent(key: "user_id")
    var user: User
    
    init() { }
    init(id: UUID? = nil, token: String, userId: User.IDValue) throws {
        self.id = id
        self.token = token
        self.$user.id = userId
        self.expiresAt = Date().addingTimeInterval(60 * 60 * 24 * 7)
    }
}

extension Auth: ModelTokenAuthenticatable {
    static let valueKey = \Auth.$token
    static let userKey = \Auth.$user
    
    var isValid: Bool {
        return expiresAt > Date()
    }
}

extension Auth {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema("auths")
                .id()
                .field("token", .string, .required)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .field("expires_at", .datetime, .required)
                .field("created_at", .datetime)
                .unique(on: "token")
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema("authentications").delete()
        }
    }
}
