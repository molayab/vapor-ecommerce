import Fluent
import Vapor

struct CreateUserViewData: Codable {
    let user: User.Public
    let roles: [AvailableRoles]
}

struct ProductsViewData: Codable {
    let user: User.Public
    let products: [Product.Public]
}

struct CreateProductViewData: Codable {
    let user: User.Public
    let categories: [Category.Public]
}

func routes(_ app: Application) throws {
    let api = app.grouped("v1")

    app.get { req in
        return "It works! This is the API endpoint. Please refer to the documentation for more information."
    }
    
    try api.register(collection: AuthenticationController())
    try api.register(collection: UsersController())
    try api.register(collection: CategoriesController())
    try api.register(collection: ProductsController())
    try api.register(collection: ProductReviewsController())
    try api.register(collection: ProductsVariantsController())
    
    /*let protected = app.routes.grouped(
        app.sessions.middleware,
        UserSessionAuthenticator(),
        User.redirectMiddleware(path: "/login"))
    
    protected.get("me") { req async throws in
        return try await req.view.render("hello", [
            "user": req.auth.get(User.self)!
        ])
    }
    
    /*protected.get("products") { req async throws in
        return try await req.view.render("products", ProductsViewData(
            user: await req.auth.get(User.self)!.asPublic(on: req.db),
            products: try await Product.query(on: req.db).all().map { try $0.asPublic() }
        ))
    }*/
    
    protected.get("products", "create") { req async throws in
        return try await req.view.render("products_create", CategoriesViewData(
            user: await req.auth.get(User.self)!.asPublic(on: req.db),
            categories: try await Category.query(on: req.db).all().map { try $0.asPublic() }
        ))
    }
    
    protected.get("categories", "create") { req async throws in
        return try await req.view.render("categories_create", CategoriesViewData(
            user: await req.auth.get(User.self)!.asPublic(on: req.db),
            categories: try await Category.query(on: req.db).all().map { try $0.asPublic() }
        ))
    }
    protected.post("categories") { req async throws in
        try Category.Create.validate(content: req)
        let payload = try req.content.decode(Category.Create.self)
        let category = Category(
            title: payload.title,
            description: payload.description)
        try await category.save(on: req.db)
        return req.redirect(to: "/products")
    }

    let protectedOnlyAdmins = protected.grouped(EnsureAdminUserMiddleware(redirectTo: "/unauthorized/role"))
    protectedOnlyAdmins.get("users") { req async throws -> View in
        var users: [User.Public] = []
        for user in try await User.query(on: req.db).all() {
            users.append(try await user.asPublic(on: req.db))
        }

        return try await req.view.render("users", UsersViewData(
            user: await req.auth.get(User.self)!.asPublic(on: req.db),
            users: users
        ))
    }
    protectedOnlyAdmins.get("users", "create") { req async throws in
        return try await req.view.render("users_create", CreateUserViewData(
            user: await req.auth.get(User.self)!.asPublic(on: req.db),
            roles: AvailableRoles.allCases
        ))
    }
    protectedOnlyAdmins.post("users") { req async throws in
        try User.Create.validate(content: req)
        let payload = try req.content.decode(User.Create.self)
        let user = try User(
            name: payload.name,
            kind: payload.kind,
            password: payload.password,
            email: payload.email)
        try await user.save(on: req.db)
        
        if let role = payload.role {
            let role = Role(
                role: role,
                userId: try user.requireID())
            try await role.save(on: req.db)
        }
        
        return req.redirect(to: "/users")
    }
    
    
    // let api = app.grouped("api")
    
    // try app.register(collection: UsersController())
    // try app.register(collection: AuthController())
    // try app.register(collection: CategoriesController())
    */
}
