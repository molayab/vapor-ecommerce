import Vapor
import Fluent

struct UsersViewData: Codable {
    let user: User.Public
    let users: [User.Public]
    let categories: [UserKind]
    let selectedCategory: UserKind?
}

struct UserViewCreateData: Codable {
    let user: User.Public
    let roles: [AvailableRoles]
    let userKinds: [UserKind]
    let option: String
}

struct UsersController: RouteCollection {
    enum AvailableOptions: String, CaseIterable {
        case natural
        case organization
    }

    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(
            UserSessionAuthenticator(),
            User.redirectMiddleware(path: "/login"))

        let restricted = protected.grouped(EnsureAdminUserMiddleware())
        restricted.get("users", use: listView)
        restricted.get("users", "create", ":option", use: createView)
        restricted.post("users", "create", ":option", use: create)
        restricted.post("users", ":userId", "activate", use: activateUser)
        restricted.post("users", ":userId", "deactivate", use: deactivateUser)
        restricted.get("users", ":userId", "delete", use: delete)
    }

    func delete(req: Request) async throws -> Response {
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        for role in try await user.$roles.get(on: req.db) {
            try await role.delete(on: req.db)
        }

        try await user.delete(on: req.db)
        return req.redirect(to: "/users")
    }

    func activateUser(req: Request) async throws -> Response {
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        user.isActive = true
        try await user.save(on: req.db)
        return req.redirect(to: "/users")
    }

    func deactivateUser(req: Request) async throws -> Response {
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        user.isActive = false
        try await user.save(on: req.db)
        return req.redirect(to: "/users")
    }

    func listView(req: Request) async throws -> View {
        let category = try? req.query.get(String.self, at: "category")
        let context = User.query(on: req.db)
        
        if let category = category, let kind = UserKind(rawValue: category), !category.isEmpty {
            context.filter(\User.$kind == kind)
        }

        var users: [User.Public] = []
        for user in try await context.paginate(for: req).items {
            users.append(try await user.asPublic(on: req.db))
        }

        return try await req.view.render("users/list", UsersViewData(
            user: await req.auth.get(User.self)!.asPublic(on: req.db),
            users: users,
            categories: UserKind.allCases,
            selectedCategory: UserKind(rawValue: category ?? "")
        ))
    }

    func createView(req: Request) async throws -> View {
        

        let option = try req.parameters.require("option", as: String.self).lowercased()
        guard AvailableOptions.allCases.map({ $0.rawValue }).contains(option) else {
            throw Abort(.badRequest)
        }

        return try await req.view.render("users/create/\(option)", UserViewCreateData(
            user: await req.auth.get(User.self)!.asPublic(on: req.db),
            roles: AvailableRoles.allCases,
            userKinds: UserKind.allCases,
            option: option
        ))
    }

    func create(req: Request) async throws -> Response {
        let option = try req.parameters.require("option", as: String.self).lowercased()
        guard let option = AvailableOptions(rawValue: option) else {
            throw Abort(.badRequest)
        }

        try User.Create.validate(content: req)
        let payload = try req.content.decode(User.Create.self)

        let newUser = try User(create: payload)

        try await newUser.save(on: req.db)
        var askedRoles = payload.role

        if case .organization = option {
            askedRoles = [.noAccess]
        }

        for askedRole in askedRoles {
            let role = Role(role: askedRole, userId: try newUser.requireID())
            try await role.save(on: req.db)
        }
        
        return req.redirect(to: "/users")
    }
}