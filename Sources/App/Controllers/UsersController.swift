import Vapor
import Fluent

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped("users")
        
        // Public API
        routes.post("create", use: createClient)
        
        // Private API
        let protected = routes.grouped(
            UserSessionAuthenticator(),
            User.guardMiddleware())
        protected.get("me", use: me)
        
        // Restricted API
        let restricted = protected.grouped(
            RoleMiddleware(roles: [.admin]))
        restricted.post("create", "employee", use: createEmployee)
        restricted.post("create", "provider", use: createProvider)
        restricted.post(":userId", "activate", use: activateUser)
        restricted.post(":userId", "deactivate", use: deactivateUser)
        restricted.delete(":userId", use: delete)
    }
    
    /// Private API
    /// GET /users/me
    /// Returns the current user
    private func me(req: Request) async throws -> User.Public {
        try await req.auth.require(User.self).asPublic(on: req.db)
    }
    
    /// Public API
    /// POST /users/create
    /// Creates a new user as client
    private func createClient(req: Request) async throws -> User.Public {
        let payload = try req.content.decode(User.Client.self)
        try User.Client.validate(content: req)
        
        let user = User.Create(
            name: payload.name,
            kind: .client,
            password: payload.password,
            email: payload.email,
            roles: [.noAccess],
            isActive: false)
        return try await user.create(on: req.db).asPublic(on: req.db)
    }
    
    /// Restricted API
    /// POST /users/create/provider
    /// Creates a new user as provider
    private func createProvider(req: Request) async throws -> User.Public {
        let payload = try req.content.decode(User.Provider.self)
        try User.Provider.validate(content: req)
        
        let user = User.Create(
            name: payload.name,
            kind: .provider,
            password: payload.password,
            email: payload.email,
            roles: [.noAccess],
            isActive: false)
        
        return try await user.create(on: req.db).asPublic(on: req.db)
    }
    
    /// Restricted API
    /// POST /users/create/employee
    /// Creates a new user as employee
    private func createEmployee(req: Request) async throws -> User.Public {
        let payload = try req.content.decode(User.Create.self)
        let user = try await payload.create(on: req.db)
        try User.Create.validate(content: req)
        
        // create
        return try await user.asPublic(on: req.db)
    }
    

    /// Restricted API
    /// POST /users/:userId/activate
    /// Activates a user
    private func activateUser(req: Request) async throws -> Response {
        try await setUserActivation(for: req, to: true)
        return Response(status: .ok)
    }

    /// Restricted API
    /// POST /users/:userId/deactivate
    /// Deactivates a user
    private func deactivateUser(req: Request) async throws -> Response {
        try await setUserActivation(for: req, to: false)
        return Response(status: .ok)
    }

    /// Restricted API
    /// DELETE /users/:userId
    /// Deletes a user
    private func delete(req: Request) async throws -> Response {
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        let roles = try await user.$roles.get(on: req.db)
        try await roles.delete(on: req.db)
        try await user.delete(on: req.db)
        return req.redirect(to: "/users")
    }

    private func setUserActivation(for req: Request, to isActive: Bool) async throws {
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        user.isActive = isActive
        try await user.save(on: req.db)
    }
}
