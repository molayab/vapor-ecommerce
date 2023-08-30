import Vapor
import Fluent

/// The controller for the checkout endpoints.
struct CheckoutController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        // Public API
        let transactions = routes.grouped("orders")
        transactions.post("checkout", use: checkout)

        // Internal API
        let requiredAuth = transactions.grouped(
            UserSessionAuthenticator(),
            User.guardMiddleware())
        let pos = requiredAuth.grouped(RoleMiddleware(roles: [.admin, .manager, .pos]))
        pos.post("checkout", ":method", use: checkoutPos)

        // Restricted API
        let restricted = requiredAuth.grouped(RoleMiddleware(roles: [.admin, .manager]))
        restricted.delete("anulate", use: anulate)
    }

    /// Public API
    /// POST /transactions/checkout
    /// This endpoint is used to create a new transaction.
    private func checkout(req: Request) async throws -> Transaction.Public {
        let payload = try req.content.get(Transaction.Create.self)
        return try await payload.create(in: req, forOrigin: .web).asPublic(on: req.db)
    }

    /// Retricted API
    /// POST /transactions/checkout/pos/:method
    /// This endpoint is used to create a new transaction.
    private func checkoutPos(req: Request) async throws -> Transaction.Public {
        try await req.ensureFeatureEnabled(.posEnabled)

        guard let methodParameter = req.parameters.get("method", as: String.self) else {
            throw Abort(.badRequest)
        }
        guard let method = Transaction.Origin(rawValue: methodParameter) else {
            throw Abort(.badRequest)
        }

        let payload = try req.content.get(Transaction.Create.self)
        return try await payload.create(in: req, forOrigin: method).asPublic(on: req.db)
    }

    /// Restricted API
    /// DELETE /transactions/anulate
    /// This endpoint is used to anulate a transaction. It will restore the stock of the 
    /// products and remove the sales.
    private func anulate(req: Request) async throws -> Response {
        let payload = try req.content.get(Transaction.Anulate.self)
        try await payload.anulate(in: req)
        return Response(status: .ok)
    }
}
