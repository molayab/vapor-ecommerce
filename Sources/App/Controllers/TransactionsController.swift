import Vapor
import Fluent

struct TransactionsController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        // Public API
        let transactions = routes.grouped("transactions")
        transactions.post("checkout", use: checkout)
        
        let requiredAuth = transactions.grouped(
            UserSessionAuthenticator(),
            User.guardMiddleware())
        requiredAuth.get("mine", use: myOrders)
        
        // Internal API
        let unauthorized = transactions.grouped(RoleMiddleware(roles: [.admin, .manager]))
        unauthorized.get("all", use: allOrders)
        unauthorized.get("pending", use: pendingOrders)
        unauthorized.get("payed", use: payedOrders)
        unauthorized.get("placed", use: placedOrders)
    }
    
    /// Public API
    /// POST /transactions/checkout
    /// This endpoint is used to create a new transaction.
    private func checkout(req: Request) async throws -> Transaction.Public {
        let payload = try req.content.get(Transaction.Create.self)
        return try await payload.create(in: req).asPublic(on: req.db)
    }
    
    /// Private API
    /// GET /transactions/mine
    /// This endpoint is used to retrieve the current user's transactions.
    private func myOrders(req: Request) async throws -> [Transaction.Public] {
        let user = try req.auth.require(User.self)
        return try await Transaction.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .all()
            .asyncMap { try await $0.asPublic(on: req.db) }
    }
    
    /// Retricted API
    /// GET /transactions/all
    /// This endpoint is used to retrieve all transactions.
    private func allOrders(req: Request) async throws -> Page<Transaction> {
        return try await Transaction.query(on: req.db)
            .paginate(for: req)
    }
    
    /// Retricted API
    /// GET /transactions/pending
    /// This endpoint is used to retrieve all pending transactions.
    private func pendingOrders(req: Request) async throws -> Page<Transaction> {
        return try await Transaction.query(on: req.db)
            .filter(\.$status == .pending)
            .paginate(for: req)
    }
    
    /// Retricted API
    /// GET /transactions/payed
    /// This endpoint is used to retrieve all payed transactions.
    private func payedOrders(req: Request) async throws -> Page<Transaction> {
        return try await Transaction.query(on: req.db)
            .filter(\.$status == .paid)
            .paginate(for: req)
    }
    
    
    /// Retricted API
    /// GET /transactions/placed
    /// This endpoint is used to retrieve all placed transactions.
    private func placedOrders(req: Request) async throws -> Page<Transaction> {
        return try await Transaction.query(on: req.db)
            .filter(\.$status == .placed)
            .paginate(for: req)
    }
}
