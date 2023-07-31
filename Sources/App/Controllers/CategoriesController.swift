import Fluent
import Vapor

protocol ViewPaginable: Codable {
    var totalPages: Int? { get }
    var currentPage: Int? { get }
    var pages: [Int]? { get }
}

struct CategoriesViewData: Codable, ViewPaginable {
    let user: User.Public
    let categories: [Category.Public]
    var totalPages: Int?
    var currentPage: Int?
    var pages: [Int]?
}

extension PageMetadata {
    var pages: [Int] {
        guard page <= pageCount else {
            return []
        }
        
        var pages: [Int] = []
        var index: Int = 0
        
        for i in max(0, page - 5)..<pageCount {
            if index == 9 {
                break
            }
            
            pages.append(i + 1)
            index += 1
        }
        
        return pages
    }
}

struct CategoriesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(
            UserSessionAuthenticator(),
            User.guardMiddleware())
        
        routes.get("categories", use: listCategories)
        protected.delete("categories", ":categoryId", use: delete)
        protected.post("categories", use: create)
    }
    
    func listCategories(req: Request) async throws -> [Category.Public] {
        return try await Category.query(on: req.db).all().map { try $0.asPublic() }
    }
    
    func create(req: Request) async throws -> Category.Public {
        try Category.Create.validate(content: req)
        let payload = try req.content.decode(Category.Create.self)
        let category = Category(model: payload)
        try await category.save(on: req.db)
        return try category.asPublic()
    }
    
    func delete(req: Request) async throws -> Response {
        guard let categoryId = req.parameters.get("categoryId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        guard let category = try await Category.find(categoryId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await category.delete(on: req.db)
        return req.redirect(to: "/categories")
    }
    
}
