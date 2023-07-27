import Vapor
import Fluent

enum AvailableRoles: String, CaseIterable, Codable, Content {
    case admin
    case manager
    case pos
    case noAccess
}

final class Role: Model, Content {
    static let schema = "roles"
    
    @ID(key: .id)
    var id: UUID?
    
    @Enum(key: "role")
    var role: AvailableRoles
    
    @Parent(key: "user_id")
    var user: User
    
    init() { }
    init(id: UUID? = nil, role: AvailableRoles, userId: UUID) {
        self.id = id
        self.role = role
        self.$user.id = userId
    }
}

extension Role {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema("roles")
                .id()
                .field("role", .string, .required)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema("roles").delete()
        }
    }
}
