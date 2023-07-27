import Vapor
import Fluent

final class Address: Model {
  static let schema = "addresses"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "street")
  var street: String

  @Field(key: "number")
  var number: String?

  @Parent(key: "state_id")
  var state: State

  @Parent(key: "country_id")
  var country: Country
}

extension Address {
  struct CreateMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
      try await database.schema("addresses")
        .id()
        .field("street", .string, .required)
        .field("number", .string)
        .field("state_id", .uuid, .required, .references("states", "id"))
        .field("country_id", .uuid, .required, .references("countries", "id"))
        .create()
    }

    func revert(on database: Database) async throws {
      try await database.schema("addresses").delete()
    }
  }
}