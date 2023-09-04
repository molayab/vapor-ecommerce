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
        restricted.get("pos", use: listAllPos)
        restricted.patch(":productId", "category", use: updateCategory)
    }

    /// Public API
    /// GET /products/:productId
    /// Returns a single product by ID
    private func listProductById(req: Request) async throws -> Product.Public {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        let model = Product.query(on: req.db).filter(\.$id == uuid)
        model.with(\.$variants, { variant in
            variant.with(\.$transactionItems, { transactionItem in
                transactionItem.with(\.$transaction)
            })
        })

        guard let product = try await model.first() else {
            throw Abort(.notFound)
        }

        return try await product.asPublic(on: req)
    }

    /// Public API
    /// GET /products
    /// Returns a paginated list of all products
    private func listAll(req: Request) async throws -> Page<Product.Public> {
        var products: Page<Product> = Page(items: [], metadata: .init(page: 1, per: 1, total: 1))
        if let query = req.query[String.self, at: "query"] {
            products = try await Product.query(on: req.db)
                .group(.or) { or in
                    or.filter(\.$title ~~ query)
                }
                .with(\.$category)
                .with(\.$variants)
                .sort(\.$createdAt, .descending)
                .paginate(for: req)
        } else {
            products = try await Product.query(on: req.db)
                .with(\.$category)
                .with(\.$variants)
                .sort(\.$createdAt, .descending)
                .paginate(for: req)
        }

        var items = [Product.Public]()
        for product in products.items {
            items.append(try await product.asPublic(on: req))
        }

        return Page<Product.Public>(
            items: items,
            metadata: products.metadata
        )
    }

    /// Restricted API
    /// GET /products/pos
    /// Returns a list of products that are available for sale
    private func listAllPos(req: Request) async throws -> [Product.Public] {
        let products = try await Product.query(on: req.db)
            .with(\.$category)
            .with(\.$variants)
            .all()

        return try await products
            .asyncFilter { try await $0.isAvailable(on: req.db) }
            .asyncMap { try await $0.asPublic(on: req) }
    }

    /// Restricted API
    /// POST /products
    /// Creates a new product
    private func create(req: Request) async throws -> Product.Public {
        let user = try req.auth.require(User.self)
        let payload = try req.content.decode(Product.Create.self)

        try Product.Create.validate(content: req)
        let product = try await payload.create(for: req, user: user)
        await req.notifyMessage("Producto creado correctamente.")

        return try await product.asPublic(on: req)
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

        let payload = try req.content.decode(Product.Create.self)
        try Product.Create.validate(content: req)
        try await payload.update(for: req, product: product)
        await req.notifyMessage("Producto actualizado correctamente.")

        return try await product.asPublic(on: req)
    }

    /// Restricted API
    /// DELETE /products/:productId
    /// Deletes a product by ID
    internal func delete(req: Request) async throws -> [String: String] {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let product = try await Product.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }

        return try await req.db.transaction { database in 
            for variant in try await product.$variants.get(on: req.db) {
                do {
                    let path = try req.application.directory.publicDirectory
                        + "images/catalog/\(product.requireID().uuidString)"
                    try await req.application.fileio.remove(path: path, eventLoop: req.eventLoop.next()).get()
                } catch {
                    await req.notifyMessage("No se pudo eliminar la imagen de la variante. \(error.localizedDescription)")
                    throw Abort(.internalServerError)
                }

                try await variant.delete(on: req.db)
            }

            for review in try await product.$reviews.get(on: req.db) {
                try await review.delete(on: req.db)
            }

            try await product.delete(on: req.db)
            await req.notifyMessage("Producto eliminado correctamente.")
            return [
                "status": "success",
                "message": "Product deleted successfully"
            ]
        }
    }

    /// Restricted API
    /// PATCH /products/:productId/category
    /// Updates a product's category by ID
    private func updateCategory(req: Request) async throws -> Product.Public {
        guard let uuid = req.parameters.get("productId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let product = try await Product.find(uuid, on: req.db) else {
            throw Abort(.notFound)
        }

        let payload = try req.content.decode(Product.UpdateCategory.self)
        try Product.UpdateCategory.validate(content: req)

        product.$category.id = payload.id

        try await product.update(on: req.db)
        return try await product.asPublic(on: req)
    }
}

struct CreateViewModel: Codable {
    let user: User
    let categories: [Category]
}
