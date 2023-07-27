import Vapor
import Fluent

final class Product: Model {
    static let schema = "products"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "description")
    var description: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Parent(key: "creator_user_id")
    var creator: User
    
    @Parent(key: "category_id")
    var category: Category
    
    @Children(for: \.$product)
    var reviews: [ProductReview]
    
    @Children(for: \.$product)
    var questions: [ProductQuestion]
    
    @Children(for: \.$product)
    var variants: [ProductVariant]

    func isAvailable(on database: Database) async throws -> Bool {
        return try await withCheckedThrowingContinuation({ next in
            $variants.get(on: database).whenComplete { result in
                switch result {
                case .success(let variants):
                    next.resume(returning: variants.contains(where: { $0.isAvailable }))
                case .failure(let error):
                    next.resume(throwing: error)
                }
            }
        })
    }
    
    func averageSalePrice(on database: Database) async throws -> Double {
        return try await withCheckedThrowingContinuation({ next in
            $variants.get(on: database).whenComplete { result in
                switch result {
                case .success(let variants):
                    next.resume(returning: variants.reduce(0, { $0 + $1.salePrice }) / Double(variants.count))
                case .failure(let error):
                    next.resume(throwing: error)
                }
            }
        })
    }
    
    func minimumSalePrice(on database: Database) async throws -> Double {
        return try await withCheckedThrowingContinuation({ next in
            $variants.get(on: database).whenComplete { result in
                switch result {
                case .success(let variants):
                    next.resume(returning: variants.map({ $0.salePrice }).min() ?? 0)
                case .failure(let error):
                    next.resume(throwing: error)
                }
            }
        })
    }
    
    func productCoverImage(on database: Database) async throws -> ProductImage? {
        return try await withCheckedThrowingContinuation({ next in
            $variants.get(on: database).whenComplete { result in
                switch result {
                case .success(let variants):
                    next.resume(returning: variants.flatMap({ $0.images }).first)
                case .failure(let error):
                    next.resume(throwing: error)
                }
            }
        })
    }
    
    func productImages(on database: Database) async throws -> [ProductImage] {
        return try await withCheckedThrowingContinuation({ next in
            $variants.get(on: database).whenComplete { result in
                switch result {
                case .success(let variants):
                    next.resume(returning: variants.flatMap({ $0.images }))
                case .failure(let error):
                    next.resume(throwing: error)
                }
            }
        })
    }
    
}

extension Product {
    struct Create: Content, Validatable {
        var title: String
        var description: String
        var creatorUserId: UUID
        var categoryId: UUID
        
        func asModel() -> Product {
            let model = Product()
            model.title = title
            model.description = description
            model.$creator.id = creatorUserId
            model.$category.id = categoryId
            return model
        }
        
        static func validations(_ validations: inout Validations) {
            validations.add("title", as: String.self, is: !.empty)
            validations.add("description", as: String.self, is: !.empty)
            validations.add("creatorUserId", as: UUID.self, is: .valid)
            validations.add("categoryId", as: UUID.self, is: .valid)
        }
    }
    
    struct Public: Content {
        var id: UUID?
        var title: String
        var description: String
        var createdAt: Date?
        var updatedAt: Date?
        var creator: User.Public
        var category: Category.Public
        var reviews: [ProductReview.Public]
        var questions: [ProductQuestion.Public]
        var variants: [ProductVariant.Public]
    }
}

extension Product {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema("products")
                .id()
                .field("title", .string, .required)
                .field("description", .string, .required)
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
