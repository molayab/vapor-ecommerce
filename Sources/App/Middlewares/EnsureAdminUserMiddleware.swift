import Vapor

/**
    # Ensure Admin User Middleware
    This middleware is used to ensure that the user is an admin.
 
    ## Usage
    ```swift
    app.grouped(EnsureAdminUserMiddleware())
    ```
 */
struct EnsureAdminUserMiddleware: AsyncMiddleware {
    var redirectTo: String?
    
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let auth = try request.auth.require(User.self)
        let roles = try await auth.$roles.get(on: request.db)
        
        guard roles.contains(where: { $0.role == .admin }) else {
            if let redirectTo {
                return request.redirect(to: redirectTo)
            } else {
                throw Abort(.unauthorized)
            }
        }
        
        return try await next.respond(to: request)
    }
}

