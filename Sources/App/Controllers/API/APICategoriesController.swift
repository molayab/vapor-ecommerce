import Vapor

/**
    # Categories Controller
    This controller handles all the routes related to categories. Admin users are able to access all routes.
 
    ## Routes
    ### Admin Role is able to access:
    - POST `/categories` - Creates a new category
        - Category.Create
            - name: String
            - description: String
    - DELETE `/categories/:categoryId` - Deletes a category by id
 */
struct APICategoriesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.group(Auth.authenticator(), EnsureAdminUserMiddleware()) { protected in
            let categories = protected.grouped("categories")
            categories.post(use: create)
            categories.delete(":categoryId", use: delete)
        }
    }
    
    private func create(req: Request) async throws -> Category {
        let input = try req.content.decode(Category.Create.self)
        let category = Category(model: input)
        
        try await category.save(on: req.db)
        return category
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("categoryId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let category = try await Category.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await category.delete(on: req.db)
        return .ok
    }
}

