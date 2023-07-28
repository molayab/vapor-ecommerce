import Vapor
import Fluent

struct UsersViewData: Codable, ViewPaginable {
    let pages: [Int]?
    let totalPages: Int?
    let currentPage: Int?
    let user: User.Public
    let users: [User.Public]
    let categories: [UserKind]
    let selectedCategory: UserKind?
    let query: String?
}

struct UserViewCreateData: Codable {
    let user: User.Public
    let roles: [AvailableRoles]
    let userKinds: [UserKind]
    let option: String
}

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(
            UserSessionAuthenticator(),
            User.redirectMiddleware(path: "/login"))

        let restricted = protected.grouped(RoleMiddleware(roles: [.admin]))
        restricted.get("users", use: listView)
        restricted.get("users", "create", ":option", use: createView)
        restricted.post("users", "create", ":option", use: create)
        restricted.post("users", ":userId", "activate", use: activateUser)
        restricted.post("users", ":userId", "deactivate", use: deactivateUser)
        restricted.delete("users", ":userId", use: delete)
    }

    func activateUser(req: Request) async throws -> Response {
        return try await setUserActivation(for: req, to: true)
    }

    func deactivateUser(req: Request) async throws -> Response {
        return try await setUserActivation(for: req, to: false)
    }

    func listView(req: Request) async throws -> View {
        let category = try? req.query.get(String.self, at: "category")
        let query = try? req.query.get(String.self, at: "q")
        let context = User.query(on: req.db)
        
        if let category = category, let kind = UserKind(rawValue: category), !category.isEmpty {
            context.filter(\User.$kind == kind)
        }
        
        if let query = query, !query.isEmpty {
            context.group(.or) { or in
                or.filter(\User.$name ~~ query)
                or.filter(\User.$email ~~ query)
            }
        }

        var users: [User.Public] = []
        let paginator = try await context.paginate(for: req)
        for user in paginator.items {
            users.append(try await user.asPublic(on: req.db))
        }

        return try await req.view.render("users/list", UsersViewData(
            pages: paginator.metadata.pages,
            totalPages: paginator.metadata.pageCount,
            currentPage: paginator.metadata.page,
            user: await req.auth.get(User.self)!.asPublic(on: req.db),
            users: users,
            categories: UserKind.allCases,
            selectedCategory: UserKind(rawValue: category ?? ""),
            query: query
        ))
    }

    func createView(req: Request) async throws -> View {
        let option = try req.parameters.require("option", as: String.self).lowercased()
        guard User.Create.Option.allCases.map({ $0.rawValue }).contains(option) else {
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
        guard let option = User.Create.Option(rawValue: option) else {
            throw Abort(.badRequest)
        }

        try User.Create.validate(content: req)
        let payload = try req.content.decode(User.Create.self)
        try await payload.create(on: req.db, option: option)
        
        return req.redirect(to: "/users")
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

    private func setUserActivation(for req: Request, to isActive: Bool) async throws -> Response {
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        user.isActive = isActive
        try await user.save(on: req.db)
        return req.redirect(to: "/users")
    }
}
