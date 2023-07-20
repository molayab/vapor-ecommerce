import Vapor
import Fluent

final class State: Model {
  static let schema = "states"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "name")
  var name: String

  @Parent(key: "country_id")
  var country: Country

  init() { }
  convenience init(name: String, countryId: Country.IDValue) throws {
    self.init()
    self.name = name
    self.$country.id = countryId
  }
}

extension State {
  struct CreateMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
      try await database.schema("states")
        .id()
        .field("name", .string, .required)
        .field("country_id", .uuid, .required, .references("countries", "id"))
        .create()
    }

    func revert(on database: Database) async throws {
      try await database.schema("states").delete()
    }
  }
}