import Vapor
import Redis
import Fluent
import Gatekeeper

struct AuthenticationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let root = routes.grouped("auth")
            .grouped(GatekeeperMiddleware(config: .init(maxRequests: 5, per: .minute)))

        // Public API
        root.post("refresh", use: refresh)
        root.post("logout", use: logout)

        // Private API
        let authenticator = root.grouped(
            User.credentialsAuthenticator(),
            User.guardMiddleware())
        authenticator.post("create", use: login)
    }

    /// Private API
    /// POST /auth/create
    /// Creates a new user session
    private func login(req: Request) async throws -> Response {
        try await req.ensureFeatureEnabled(.loginEnabled)

        let user = try req.auth.require(User.self)
        guard user.isActive else {
            throw Abort(.unauthorized)
        }

        let authorization = try await Auth(forRequest: req, user: user)
        let refresh = authorization.refreshToken

        // Create the secure cookie for refresh token
        let cookie = HTTPCookies.Value(
            string: refresh,
            expires: .distantFuture,
            isHTTPOnly: true)
        req.cookies["refresh"] = cookie

        let response = Response(status: .ok)
        response.cookies["refresh"] = cookie
        response.body = await Response.Body(
            data: try JSONEncoder().encode(
                authorization.asPublic(on: req)))

        return response
    }

    /// Public API
    /// POST /auth/refresh
    /// Refreshes a user session
    func refresh(req: Request) async throws -> Response {
        guard let refresh = req.cookies["refresh"]?.string else {
            throw Abort(.unauthorized)
        }

        let authorization = try await Auth.refresh(in: req, token: refresh)
        let response = Response(status: .ok)
        response.body = .init(
            data: try JSONEncoder().encode(await authorization.asPublic(on: req)))
        response.cookies["refresh"] = HTTPCookies.Value(
            string: authorization.refreshToken,
            expires: .distantFuture,
            isHTTPOnly: true)

        return response
    }

    /// Private API
    /// POST /auth/logout
    /// Logs out a user session
    func logout(req: Request) throws -> Response {
        req.auth.logout(User.self)
        return Response(status: .ok)
    }
}
