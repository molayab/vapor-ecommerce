import Vapor
import Fluent

struct OrderStats: Content {
    struct Sale: Content {
        var name: String
        var value: Int?
        var sales: Int?
        var origin: Transaction.Origin?
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
        transactions.post("checkout", use: checkout)
        
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
        unauthorized.get("stats", use: orderStats)
        
        let pos = requiredAuth.grouped(RoleMiddleware(roles: [.admin, .manager, .pos]))
        pos.post("checkout", ":method", use: checkoutPos)
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
        guard let methodParameter = req.parameters.get("method", as: String.self) else {
            throw Abort(.badRequest)
        }
        guard let method = Transaction.Origin(rawValue: methodParameter) else {
            throw Abort(.badRequest)
        }
        
        let payload = try req.content.get(Transaction.Create.self)
        return try await payload.create(in: req, forOrigin: method).asPublic(on: req.db)
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
    
    private func orderStats(req: Request) async throws -> OrderStats {
        let calendar = Calendar.current
        let months = calendar.monthSymbols
        let txs = try await Transaction
            .query(on: req.db)
            .join(TransactionItem.self, on: \Transaction.$id == \TransactionItem.$transaction.$id)
            .filter(\.$status == .paid)
            .all()
        
        var salesByProduct: [OrderStats.Sale] = []
        var salesByMonth: [OrderStats.Sale] = []
        var salesBySource: [OrderStats.Sale] = Transaction.Origin.allCases.map {
            OrderStats.Sale(name: $0.rawValue, value: 0)
        }
        
        for tx in txs {
            // Join transactions with items
            let item = try tx.joined(TransactionItem.self)
            
            // Group sales by product
            let variant = try await item.$productVariant.get(on: req.db)
            let product = try await variant.$product.get(on: req.db)
            
            if let index = salesByProduct.firstIndex(where: { $0.name == product.title }) {
                if let value = salesByProduct[index].value {
                    salesByProduct[index].value =
                        (salesByProduct[index].value ?? 0) + (Int(item.total) * item.quantity)
                }
            } else {
                salesByProduct.append(.init(
                    name: product.title,
                    value: Int(item.total) * item.quantity))
            }
            
            // Get annual sales by month
            if let date = tx.payedAt {
                let txMonth = calendar.component(.month, from: date)
                if let index = salesByMonth.firstIndex(where: { $0.name == months[txMonth - 1] }) {
                    if let sales = salesByMonth[index].sales {
                        salesByMonth[index].sales =
                            (salesByMonth[index].sales ?? 0) + (Int(item.total) * item.quantity)
                    }
                } else {
                    salesByMonth.append(.init(
                        name: months[txMonth - 1],
                        sales: Int(item.total) * item.quantity))
                }
            }
            
            // Group sales by source
            if let index = salesBySource.firstIndex(where: { $0.name == tx.origin.rawValue }) {
                if let value = salesBySource[index].value {
                    salesBySource[index].value =
                        (salesBySource[index].value ?? 0) + (Int(item.total) * item.quantity)
                }
            }
        }

        return OrderStats(
            salesByProduct: salesByProduct,
            salesByMonth: salesByMonth,
            salesThisMonth: salesByMonth.reduce(0) { $0 + ($1.sales ?? 0) },
            salesMonthTitle: months[calendar.component(.month, from: Date()) - 1],
            salesBySource: salesBySource,
            lastSales: try await txs
                .prefix(5)
                .asyncMap {
                    try await $0.asPublic(on: req.db)
                })
    }
}
