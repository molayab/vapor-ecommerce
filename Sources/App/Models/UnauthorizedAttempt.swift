import Vapor
import Fluent

final class UnauthorizedAttempt: Model {
  static let schema = "unauthorized_attempts"

  @ID(key: .id)
  var id: UUID?

  @Parent(key: "user_id")
  var user: User

  @Field(key: "ip_address")
  var ipAddress: String

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Field(key: "expires_at")
  var expiresAt: Date

  init() { }
  convenience init(id: UUID? = nil, userId: User.IDValue, ipAddress: String, expiresAt: Date) throws {
    self.init()
    self.id = id
    self.$user.id = userId
    self.ipAddress = ipAddress
    self.expiresAt = expiresAt
  }
}

extension UnauthorizedAttempt {
  struct CreateMigration : AsyncMigration {
    func prepare(on database: Database) async throws {
      try await database.schema("unauthorized_attempts")
        .id()
        .field("user_id", .uuid, .required, .references("users", "id"))
        .field("ip_address", .string, .required)
        .field("created_at", .datetime, .required)
        .field("expires_at", .datetime, .required)
        .create()
    }

    func revert(on database: Database) async throws {
      try await database.schema("unauthorized_attempts").delete()
    }
  }
}