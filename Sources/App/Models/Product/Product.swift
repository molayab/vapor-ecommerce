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

    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?

    @Field(key: "is_published")
    var isPublished: Bool

    @OptionalParent(key: "creator_user_id")
    var creator: User?

    @Parent(key: "category_id")
    var category: Category

    @Children(for: \.$product)
    var reviews: [ProductReview]

    @Children(for: \.$product)
    var questions: [ProductQuestion]

    @Field(key: "cover_image_url")
    var coverImageUrl: String?

    @Children(for: \.$product)
    var variants: [ProductVariant]
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    func asPublic(on request: Request) async throws -> Public {
        let database = request.db
        let creator = try await self.$creator.get(on: database)
        let category = try await self.$category.get(on: database)
        let reviews = try await self.$reviews.get(on: database).sorted(
            by: { $0.createdAt ?? Date() > $1.createdAt ?? Date() }).prefix(100)

        return await Public(
            id: try requireID(),
            title: title,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
            creator: try creator?.requireID(),
            category: try await category.asPublic(on: database),
            reviews: try reviews.map({ try $0.asPublic() }),
            questions: [], // try questions.map({ try $0.asPublic() }),
            variants: try await self.$variants
                .get(on: database)
                .asyncMap({ try await $0.asPublic(request: request) }),
            minimumSalePrice: try minimumSalePrice(on: database),
            averageSalePrice: try averageSalePrice(on: database),
            stock: try calculateStock(on: database),
            numberOfStars: try numberOfStars(on: database),
            isPublished: isPublished
        )
    }

    func numberOfStars(on database: Database) async throws -> Int {
        return try await withCheckedThrowingContinuation({ next in
            $reviews.get(on: database).whenComplete { result in
                switch result {
                case .success(let reviews) where reviews.count > 0:
                    next.resume(returning: reviews.reduce(0, { $0 + ($1.score) }) / reviews.count)
                case .success:
                    next.resume(returning: 0)
                case .failure(let error):
                    next.resume(throwing: error)
                }
            }
        })
    }

    func calculateStock(on database: Database) async throws -> Int {
        return try await withCheckedThrowingContinuation({ next in
            $variants.get(on: database).whenComplete { result in
                switch result {
                case .success(let variants):
                    next.resume(returning: variants.reduce(0, { $0 + $1.stock }))
                case .failure(let error):
                    next.resume(throwing: error)
                }
            }
        })
    }

    func isAvailable(on database: Database) async throws -> Bool {
        return try await withCheckedThrowingContinuation({ next in
            $variants.get(on: database).whenComplete { result in
                switch result {
                case .success(let variants):
                    next.resume(returning: variants.contains(where: { $0.isAvailable && $0.stock > 0 }))
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
                    guard variants.count > 0 else {
                        return next.resume(returning: 0)
                    }

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
}

extension Product {
    struct Create: Content, Validatable {
        var title: String
        var description: String
        var category: UUID
        var isPublished: Bool

        @discardableResult
        func create(for req: Request, user: User) async throws -> Product {
            let model = Product()
            model.title = title
            model.description = description
            model.$creator.id = try user.requireID()
            model.$category.id = category
            model.isPublished = isPublished
            try await model.create(on: req.db)
            return model
        }

        @discardableResult
        func update(for req: Request, product: Product) async throws -> Product {
            product.title = title
            product.description = description
            product.$category.id = category
            product.isPublished = isPublished
            try await product.update(on: req.db)
            return product
        }

        static func validations(_ validations: inout Validations) {
            validations.add("title", as: String.self, is: !.empty)
            validations.add("description", as: String.self, is: !.empty)
            validations.add("category", as: UUID.self, is: .valid)
            validations.add("isPublished", as: Bool.self, is: .valid)
        }
    }

    struct Public: Content {
        var id: UUID?
        var title: String
        var description: String
        var createdAt: Date?
        var updatedAt: Date?
        var creator: UUID?
        var category: Category.Public
        var reviews: [ProductReview.Public]
        var questions: [ProductQuestion.Public]
        var variants: [ProductVariant.Public]
        var minimumSalePrice: Double
        var averageSalePrice: Double
        var stock: Int
        var numberOfStars: Int
        var isPublished: Bool
    }

    struct UpdateCategory: Content, Validatable {
        var id: UUID

        static func validations(_ validations: inout Validations) {
            validations.add("id", as: UUID.self, is: .valid)
        }
    }
}

extension Product {
    struct CreateMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema("products")
                .id()
                .field("title", .string, .required)
                .field("description", .string, .required)
                .field("creator_user_id", .uuid, .references("users", "id"))
                .field("editor_user_id", .uuid, .references("users", "id"))
                .field("category_id", .uuid, .required, .references("categories", "id"))
                .field("is_published", .bool, .required, .custom("DEFAULT FALSE"))
                .field("cover_image_url", .string)
                .field("createdAt", .datetime)
                .field("updatedAt", .datetime)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("products").delete()
        }
    }

    struct AddDeleteFieldMigration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema("products")
                .field("deleted_at", .datetime)
                .update()
        }

        func revert(on database: Database) async throws {
            try await database.schema("products")
                .deleteField("deleted_at")
                .update()
        }
    }
}
