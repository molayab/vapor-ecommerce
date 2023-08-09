import Fluent
import Vapor

final class Address: Model {
    static var schema: String = "addresses"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "street")
    var street: String
    
    @Field(key: "city")
    var city: String
    
    @Field(key: "state")
    var state: String
    
    @Field(key: "zip")
    var zip: String
    
    @Enum(key: "country")
    var country: Country
    
    @Parent(key: "user_id")
    var user: User
    
    func asPublic() -> Public {
        .init(
            street: street,
            city: city,
            state: state,
            zip: zip,
            country: country
        )
    }
}

extension Address {
    struct Public: Content {
        var street: String
        var city: String
        var state: String
        var zip: String
        var country: Country
    }
    
    typealias Create = Public
}

extension Address.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("street", as: String.self, is: !.empty)
        validations.add("city", as: String.self, is: !.empty)
        validations.add("state", as: String.self, is: !.empty)
        validations.add("zip", as: String.self, is: !.empty)
        validations.add("country", as: String.self, is: !.empty)
    }
}

extension Address {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(schema)
                .id()
                .field("street", .string, .required)
                .field("city", .string, .required)
                .field("state", .string, .required)
                .field("zip", .string, .required)
                .field("country", .string, .required)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(schema).delete()
        }
    }
}
