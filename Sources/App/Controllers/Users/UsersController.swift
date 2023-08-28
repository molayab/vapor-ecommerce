import Vapor
import Fluent

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped("users")

        // Public API
        routes.post("create", use: createClient)
        routes.get("available", "roles", use: roles)
        routes.get("available", "national", "ids", use: availableNationalIdTypes)

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

        restricted.get("all", "employees", use: getAllEmployees)
        restricted.get("all", "providers", use: getAllProviders)
        restricted.get("all", "clients", use: getAllClients)
    }

    private func getAllEmployees(req: Request) async throws -> Page<User.Public> {
        let users = try await User.query(on: req.db)
            .filter(\.$kind == .employee)
            .paginate(for: req)

        return try await Page(
            items: users.items.asyncMap { try await $0.asPublic(on: req.db) },
            metadata: users.metadata)
    }

    private func getAllProviders(req: Request) async throws -> Page<User.Public> {
        let users = try await User.query(on: req.db)
            .filter(\.$kind == .provider)
            .paginate(for: req)

        return try await Page(
            items: users.items.asyncMap { try await $0.asPublic(on: req.db) },
            metadata: users.metadata)
    }

    private func getAllClients(req: Request) async throws -> Page<User.Public> {
        let users = try await User.query(on: req.db)
            .filter(\.$kind == .client)
            .paginate(for: req)

        return try await Page(
            items: users.items.asyncMap { try await $0.asPublic(on: req.db) },
            metadata: users.metadata)
    }

    /// Private API
    /// GET /users/me
    /// Returns the current user
    private func me(req: Request) async throws -> User.Public {
        try await req.auth.require(User.self).asPublic(on: req.db)
    }

    private func roles(req: Request) async throws -> [String] {
        AvailableRoles.allCases.map { $0.rawValue }
    }

    private func availableNationalIdTypes(req: Request) async throws -> [User.NationalIdType.Public] {
        User.NationalIdType.allCases.map { $0.asPublic() }
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
            isActive: false,
            addresses: payload.addresses ?? [])
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
            password: UUID().uuidString,
            email: payload.email,
            roles: [.noAccess],
            isActive: false,
            addresses: payload.addresses)
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
