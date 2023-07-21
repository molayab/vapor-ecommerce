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
        (page..<pageCount).map { $0 }.prefix(5).map { $0 }
    }
}

struct CategoriesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(
            UserSessionAuthenticator(),
            User.redirectMiddleware(path: "/login"))
            
        protected.get("categories", use: listView)
        protected.get("categories", "create", use: createView)
        protected.get("categories", ":categoryId", "delete", use: delete)
        protected.post("categories", "create", use: create)
    }
    
    func listView(req: Request) async throws -> View {
        let query = try? req.query.get(String.self, at: "q")
        let categories = Category.query(on: req.db)
        
        if let query = query {
            categories.filter(\.$title ~~ query)
        }
        
        let paginator = try await categories.paginate(for: req)
        
        return try await req.view.render("categories/list", CategoriesViewData(
            user: await req.auth.get(User.self)!.asPublic(on: req.db),
            categories: paginator.items.map { try $0.asPublic() },
            totalPages: paginator.metadata.pageCount,
            currentPage: paginator.metadata.page,
            pages: paginator.metadata.pages
        ))
    }
    
    func createView(req: Request) async throws -> View {
        return try await req.view.render("categories/create", CategoriesViewData(
            user: await req.auth.get(User.self)!.asPublic(on: req.db),
            categories: try await Category.query(on: req.db).all().map { try $0.asPublic() }
        ))
    }
    
    func create(req: Request) async throws -> Response {
        try Category.Create.validate(content: req)
        let payload = try req.content.decode(Category.Create.self)
        let category = Category(model: payload)
        try await category.save(on: req.db)
        return req.redirect(to: "/categories")
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
