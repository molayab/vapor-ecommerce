import Vapor
import Fluent

struct RoleMiddleware: AsyncMiddleware {
  let roles: [AvailableRoles]

  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    guard let user = try? request.auth.require(User.self) else {
      throw Abort(.unauthorized)
    }

    let userRoles = try await user.$roles.get(on: request.db)
    guard userRoles.contains(where: { roles.contains($0.role) }) else {
      throw Abort(.unauthorized)
    }

    return try await next.respond(to: request)
  }
}