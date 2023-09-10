import Vapor
import Fluent

struct UserSessionAuthenticator: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        var payload: Auth!

        do {
            payload = try request.jwt.verify(as: Auth.self)
        } catch {
            throw Abort(.forbidden)
        }

        guard let user = try await User.find(payload.userId, on: request.db) else {
            throw Abort(.unauthorized)
        }

        request.auth.login(user)
        return try await next.respond(to: request)
    }
}
