import Vapor
import Fluent

struct ProductsController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let products = routes.grouped("products")
    
    let restricted = products.grouped([
        UserSessionAuthenticator(),
        User.redirectMiddleware(path: "/login"),
        RoleMiddleware(roles: [.admin, .manager])
    ])

    restricted.post(use: create)
    restricted.get("create", use: createView)
  }

  private func create(req: Request) async throws -> Product.Public {
      let user = try req.auth.require(User.self)
      let payload = try req.content.decode(Product.Create.self)
      
      try Product.Create.validate(content: req)
      let product = try await payload.create(for: req, user: user)
    
      return try await product.asPublic(on: req.db)
  }

  private func createView(req: Request) async throws -> View {
    let user = try req.auth.require(User.self)
    let categories = try await Category.query(on: req.db).all()

    return try await req.view.render("products/create", CreateViewModel(user: user, categories: categories))
  }
}

struct CreateViewModel: Codable {
  let user: User
  let categories: [Category]
}
