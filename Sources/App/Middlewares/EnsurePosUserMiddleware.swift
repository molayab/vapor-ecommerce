import Vapor

/**
    # Ensure POS User Middleware
    This middleware is used to ensure that the user is a POS user. It allows any admin to access the
    route as well.

    ## Usage
    ```swift
    app.grouped(EnsurePosUserMiddleware())
    ```
 */
struct EnsurePosUserMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let auth = try request.auth.require(User.self)
        let roles = try await auth.$roles.get(on: request.db)
        
        guard roles.contains(where: { $0.role == .pos }) || roles.contains(where: { $0.role == .admin }) else {
            throw Abort(.unauthorized)
        }
        
        return try await next.respond(to: request)
    }
}

