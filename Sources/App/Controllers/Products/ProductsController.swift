import Vapor
import Fluent

struct ProductsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let products = routes.grouped("products")
        
        // Public API
        products.get(use: listAll)
        products.get(":productId", use: listProductById)
        
        // Restricted API
        let restricted = products.grouped([
            UserSessionAuthenticator(),
            User.guardMiddleware(),
            RoleMiddleware(roles: [.admin, .manager])
        ])
        
        restricted.post(use: create)
        restricted.delete(":productId", use: delete)
        restricted.patch(":productId", use: update)
    }
    
    /// Public API
    /// GET /products/:productId
    /// Returns a single product by ID
    private func listProductById(req: Request) async throws -> Product.Public {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let product = try await Product.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try await product.asPublic(on: req.db)
    }
    
    /// Public API
    /// GET /products
    /// Returns a paginated list of all products
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
    
    /// Restricted API
    /// POST /products
    /// Creates a new product
    private func create(req: Request) async throws -> Product.Public {
        let user = try req.auth.require(User.self)
        let payload = try req.content.decode(Product.Create.self)
        
        try Product.Create.validate(content: req)
        let product = try await payload.create(for: req, user: user)
        
        return try await product.asPublic(on: req.db)
    }
    
    /// Restricted API
    /// PATCH /products/:productId
    /// Updates a product by ID (not including variants)
    private func update(req: Request) async throws -> Product.Public {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let product = try await Product.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let user = try req.auth.require(User.self)
        let payload = try req.content.decode(Product.Create.self)
        
        try Product.Create.validate(content: req)
        try await payload.update(for: req, product: product)
        
        return try await product.asPublic(on: req.db)
    }
    
    /// Restricted API
    /// DELETE /products/:productId
    /// Deletes a product by ID
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
        
        for review in try await product.$reviews.get(on: req.db) {
            try await review.delete(on: req.db)
        }
        
        try await product.delete(on: req.db)
        return Response(status: .ok)
    }
    
}

struct CreateViewModel: Codable {
    let user: User
    let categories: [Category]
}
