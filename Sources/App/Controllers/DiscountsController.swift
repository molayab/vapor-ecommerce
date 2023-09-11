import Vapor
import Fluent

struct DiscountsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let discounts = routes.grouped("discounts")
        
        let requiredAuth = discounts.grouped(
            UserSessionAuthenticator(),
            User.guardMiddleware(),
            RoleMiddleware(roles: [.admin, .manager, .pos]))
        requiredAuth.get(":code", use: getDiscount)
    }
    
    /// Retricted API
    /// GET /discounts/:code
    /// This endpoint is used to retrieve a discount by code.
    private func getDiscount(req: Request) async throws -> Discount.Public {
        guard let code = req.parameters.get("code", as: String.self) else {
            throw Abort(.badRequest)
        }
        
        guard let discount = try await Discount.query(on: req.db)
            .filter(\.$code == code)
            .first() else {
            throw Abort(.notFound)
        }
        
        return try discount.asPublic()
    }
    
}
