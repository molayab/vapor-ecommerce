import Vapor
import Redis
import Fluent
import Gatekeeper

struct AuthenticationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let root = routes
            .grouped("auth")

        // Public API
        root.post("refresh", use: refresh)
        root.post("logout", use: logout)

        // Private API
        let authenticator = root.grouped(
            User.credentialsAuthenticator())
        authenticator.post("create", use: login)
    }

    /// Private API
    /// POST /auth/create
    /// Creates a new user session
    private func login(req: Request) async throws -> Response {
        try await req.ensureFeatureEnabled(.loginEnabled)
        try await req.limitTotalRequests(
            to: settings.gatekeeper.maxLoginAttemptsPerMinute,
            email: req.content.get(String.self, at: "username"))

        let user = try req.auth.require(User.self)
        guard user.isActive && !user.isDeleted else {
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
        try response.content.encode(await authorization.asPublic(on: req))

        return response
    }

    /// Public API
    /// POST /auth/refresh
    /// Refreshes a user session
    func refresh(req: Request) async throws -> Response {
        try await req.limitTotalRequests(
            to: settings.gatekeeper.maxLoginAttemptsPerMinute,
            email: (req.cookies["refresh"]?.string ?? UUID().uuidString).sha256())

        guard let refresh = req.cookies["refresh"]?.string else {
            return Response(status: .ok)
        }

        let authorization = try await Auth.refresh(in: req, token: refresh)
        let response = Response(status: .ok)
        try response.content.encode(await authorization.asPublic(on: req))
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

extension Request {
    func limitTotalRequests(to max: Int, email: String, prefix: String = "req_attempts_for_") async throws {
        let key = RedisKey(prefix + email)
        let count = try await redis.increment(key).get()

        // Set the TTL of the restriction to 5 minute and increment the time 
        // by 1 minute if the user is still making requests
        _ = try await redis.expire(key, after: .minutes(5)).get()
        guard count <= max else {
            throw Abort(.tooManyRequests)
        }
    }
}