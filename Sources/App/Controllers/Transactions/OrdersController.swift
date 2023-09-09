import Vapor
import Fluent

struct OrderStats: Content {
    struct Sale: Content {
        var name: String
        var value: Int?
        var sales: Int?
        var origin: Transaction.Origin?
        var cost: Int?
    }

    var salesByProduct: [Sale]
    var salesByMonth: [Sale]
    var salesThisMonth: Int
    var salesMonthTitle: String
    var salesBySource: [Sale]
    var lastSales: [Transaction.Public]
}

struct OrdersController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        // Public API
        let transactions = routes.grouped("orders")

        let requiredAuth = transactions.grouped(
            UserSessionAuthenticator(),
            User.guardMiddleware())
        requiredAuth.get("mine", use: myOrders)

        // Internal API
        let unauthorized = requiredAuth.grouped(RoleMiddleware(roles: [.admin, .manager]))
        unauthorized.get("all", use: allOrders)
        unauthorized.get("pending", use: pendingOrders)
        unauthorized.get("payed", use: payedOrders)
        unauthorized.get("placed", use: placedOrders)
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
            .sort(\.$createdAt, .descending)
            .with(\.$items) { item in
                item.with(\.$productVariant) { variant in
                    variant.with(\.$product)
                }
            }
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
