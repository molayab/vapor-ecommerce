import Vapor
import Fluent

struct ProductsController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let products = routes.grouped("products")
    
    let restricted = products.grouped([
        UserSessionAuthenticator(),
        User.redirectMiddleware(path: "/login"),
        // RoleMiddleware(roles: [.admin])
    ])

    restricted.post(use: create)
    restricted.get("create", use: createView)
  }

  private func create(req: Request) async throws -> Response {
    let user = try req.auth.require(User.self)
    let payload = try req.content.decode(Product.Create.self)
    let model = payload.asModel()

    return Response(status: .ok)
  }

  private func createView(req: Request) async throws -> View {
    let user = try req.auth.require(User.self)

    return try await req.view.render("products/create", user)
  }
}