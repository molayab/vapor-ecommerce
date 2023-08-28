import Vapor
import Fluent

struct SalesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let sales = routes.grouped("finance", "sales")

        // Restricted API
        let usersAuth = sales.grouped(UserSessionAuthenticator(), User.guardMiddleware())
        let restricted = usersAuth.grouped(RoleMiddleware(roles: [.admin, .manager]))

        restricted.get(use: getSalesPaginated)
        restricted.get("all", use: getSales)
    }

    private func getSales(req: Request) async throws -> [Sale.Public] {
        let sales = try await Sale.query(on: req.db)
            .all()

        return sales.map { $0.asPublic() }
    }

    private func getSalesPaginated(req: Request) async throws -> Page<Sale.Public> {
        let sales = try await Sale.query(on: req.db)
            .paginate(for: req)

        return sales.map { $0.asPublic() }
    }
}
