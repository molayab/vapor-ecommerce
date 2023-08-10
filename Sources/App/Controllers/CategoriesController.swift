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
        restricted.post(use: create)
    }
    
    /// Public API
    /// GET /categories
    /// Returns all categories
    func listCategories(req: Request) async throws -> [Category.Public] {
        return try await Category.query(on: req.db).all().map { try $0.asPublic() }
    }
    
    /// Restricted API
    /// POST /categories
    /// Creates a new category
    func create(req: Request) async throws -> Category.Public {
        try Category.Create.validate(content: req)
        let payload = try req.content.decode(Category.Create.self)
        let category = Category(model: payload)
        try await category.save(on: req.db)
        return try category.asPublic()
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
        
        try await category.delete(on: req.db)
        return Response(status: .ok)
    }
}
