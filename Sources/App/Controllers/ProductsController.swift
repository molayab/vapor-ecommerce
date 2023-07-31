import Vapor
import Fluent

struct ProductsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let products = routes.grouped("products")
        let restricted = products.grouped([
            UserSessionAuthenticator(),
            User.guardMiddleware(),
            RoleMiddleware(roles: [.admin, .manager])
        ])
        
        restricted.get(use: listAll)
        restricted.post(use: create)
        restricted.delete(":productId", use: delete)
        restricted.get(":productId", use: listProductById)
    }
    
    private func listProductById(req: Request) async throws -> Product.Public {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let product = try await Product.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try await product.asPublic(on: req.db)
    }
    
    
    
    private func listAll(req: Request) async throws -> Page<Product.Public> {
        let products = try await Product.query(on: req.db)
            .with(\.$category)
            .with(\.$variants)
            .with(\.$variants, { variant in
                variant.with(\.$images)
            })
            .paginate(PageRequest(
                page: req.parameters.get("page", as: Int.self) ?? 1,
                per: 100))
        
        var items = [Product.Public]()
        for product in products.items {
            items.append(try await product.asPublic(on: req.db))
        }
        
        return Page<Product.Public>(
            items: items,
            metadata: products.metadata
        )
    }
    
    
    private func create(req: Request) async throws -> Product.Public {
        let user = try req.auth.require(User.self)
        let payload = try req.content.decode(Product.Create.self)
        
        try Product.Create.validate(content: req)
        let product = try await payload.create(for: req, user: user)
        
        return try await product.asPublic(on: req.db)
    }
    
    private func delete(req: Request) async throws -> Response {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let product = try await Product.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }
        
        for variant in try await product.$variants.get(on: req.db) {
            for image in try await variant.$images.get(on: req.db) {
                try await image.deleteImage(on: req)
            }
            
            try await variant.delete(on: req.db)
        }
        
        try await product.delete(on: req.db)
        return Response(status: .ok)
    }
    
}

struct CreateViewModel: Codable {
    let user: User
    let categories: [Category]
}
