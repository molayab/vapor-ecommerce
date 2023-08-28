import Vapor
import Fluent

struct RoleMiddleware: AsyncMiddleware {
  let roles: [AvailableRoles]

  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    let user = try request.auth.require(User.self)
    let userRoles = try await user.$roles.get(on: request.db).map({ $0.role })
    guard userRoles.contains(where: { roles.contains($0) }) else {
      throw Abort(.unauthorized)
    }

    return try await next.respond(to: request)
  }
}
