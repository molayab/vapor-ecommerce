import Vapor
import Fluent

enum UserKind: String, CaseIterable , Codable {
    case employee
    case client
    case provider
}

/**
    # User Model
    This model is used to store the user's information.
 
    ## Properties
    - `id`: UUID
    - `name`: String
    - `password`: String
    - `email`: String
    - `role`: Role
    - `createdAt`: Date
    - `updatedAt`: Date
    - `isActive`: Bool
 */
final class User: Model {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "password")
    var password: String
    
    @Field(key: "email")
    var email: String

    @Enum(key: "kind")
    var kind: UserKind
    
    @Children(for: \.$user)
    var roles: [Role]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Field(key: "is_active")
    var isActive: Bool
    
    init() { }
    convenience init(create: Create) throws {
        self.init()
        self.name = create.name
        if let lastName = create.lastName {
            self.name += " \(lastName)"
        }

        if let password = create.password {
            self.password = try Bcrypt.hash(password)
            self.isActive = create.isActive
        } else {
            self.password = try Bcrypt.hash("password")
            self.isActive = false
        }
        
        self.email = create.email
        self.kind = create.kind
    }
    
    private func gravatar() -> String {
        let computed = Insecure.MD5.hash(data: email.data(using: .utf8)!)
        return "https://www.gravatar.com/avatar/\(computed.map { String(format: "%02hhx", $0) }.joined())"
    }

    func asPublic(on database: Database) async throws -> User.Public {
        let roles = (try await self.$roles.get(on: database)).map { $0.role }

        return User.Public(
            id: try self.requireID(),
            name: self.name,
            kind: self.kind,
            email: self.email,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            isActive: self.isActive,
            roles: roles,
            rolesString: roles.map { $0.rawValue }.joined(separator: ", "),
            gravatar: gravatar()
        )
    }
}

extension User {
    struct Create: Codable {
        var name: String
        var lastName: String?
        var kind: UserKind
        var password: String?
        var email: String
        var role: [AvailableRoles]
        var isActive: Bool
    }
    
    struct Public: Content {
        var id: UUID?
        var name: String
        var kind: UserKind
        var email: String
        var createdAt: Date?
        var updatedAt: Date?
        var isActive: Bool
        var roles: [AvailableRoles]
        var rolesString: String
        var gravatar: String
    }
}

extension User: SessionAuthenticatable {
    var sessionID: String { self.email }
}

extension User: Authenticatable { }
extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
    }
}

extension User: ModelCredentialsAuthenticatable { }
extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password
    
    func verify(password: String) throws -> Bool {
        return try Bcrypt.verify(password, created: self.password)
    }
    
    func generateToken() throws -> Auth {
        let token = SHA256.hash(data: [UInt8].random(count: 64)).hexEncodedString()
        return try Auth(token: token, userId: self.requireID())
    }
}

extension User {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema("users")
                .id()
                .field("name", .string, .required)
                .field("kind", .string, .required)
                .field("password", .string, .required)
                .field("email", .string, .required)
                .field("created_at", .datetime)
                .field("updated_at", .datetime)
                .field("is_active", .bool, .required)
                .unique(on: "email")
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema("users").delete()
        }
    }
}
