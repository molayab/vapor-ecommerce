import Fluent
import Vapor

struct CategoriesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped("categories")
        
        // Public API
        routes.get(use: listCategories)
        
        // Private API
        let protected = routes.grouped(
            UserSessionAuthenticator(),
            User.guardMiddleware())
        
        // Restricted API
        let restricted = protected.grouped(
            RoleMiddleware(roles: [.admin, .manager]))
        
        restricted.delete(":categoryId", use: delete)
        restricted.patch(":categoryId", use: update)
        restricted.post(use: create)
    }
    
    /// Public API
    /// GET /categories
    /// Returns all categories
    func listCategories(req: Request) async throws -> [Category.Public] {
        return try await Category.query(on: req.db).all().asyncMap { try await $0.asPublic(on: req.db) }
    }
    
    /// Restricted API
    /// POST /categories
    /// Creates a new category
    func create(req: Request) async throws -> Category.Public {
        try Category.Create.validate(content: req)
        let payload = try req.content.decode(Category.Create.self)
        let category = Category(model: payload)
        try await category.save(on: req.db)
        return try await category.asPublic(on: req.db)
    }
    
    /// Restricted API
    /// DELETE /categories/:categoryId
    /// Deletes a category
    func delete(req: Request) async throws -> Response {
        guard let categoryId = req.parameters.get("categoryId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let category = try await Category.find(categoryId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let products = try await category.$products.get(on: req.db)
        if !products.isEmpty {
            throw Abort(.badRequest, reason: "Cannot delete a category that has products")
        }
        
        try await category.delete(on: req.db)
        return Response(status: .ok)
    }
    
    /// Restricted API
    /// PATCH /categories/:categoryId
    /// Updates a category
    func update(req: Request) async throws -> Category.Public {
        guard let categoryId = req.parameters.get("categoryId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let category = try await Category.find(categoryId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try Category.Create.validate(content: req)
        let payload = try req.content.decode(Category.Create.self)
        category.title = payload.title
        try await category.save(on: req.db)
        return try await category.asPublic(on: req.db)
    }
}
