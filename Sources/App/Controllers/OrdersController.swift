import Vapor
import Fluent
import FluentPostgresDriver

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
    
    /// Retricted API
    /// GET /transactions/stats
    /// This endpoint is used to retrieve all transactions stats.
    private func orderStats(req: Request) async throws -> OrderStats {
        if let psql = req.db as? PostgresDatabase {
            let salesByMonthQuery = try await psql.simpleQuery(
"""
SELECT
    to_char(date(transactions.payed_at),'MM') AS _month,
    SUM(I.total) AS sales,
    SUM(V.price) AS cost,
    SUM(I.quantity)::INTEGER AS count
FROM transactions
INNER JOIN transaction_items AS I ON transactions.id = I.transaction_id
INNER JOIN product_variants AS V ON I.product_variant_id = V.id
WHERE status = 'paid'
AND transactions.payed_at > (now() - interval '1 year')
AND date_part('year', transactions.payed_at) = date_part('year', CURRENT_DATE)
GROUP BY _month
ORDER BY _month
""").get()
            let salesBySourceQuery = try await psql.simpleQuery(
"""
SELECT transactions.origin, SUM(I.total)
FROM transactions
INNER JOIN transaction_items AS I ON transactions.id = I.transaction_id
INNER JOIN product_variants AS V ON I.product_variant_id = V.id
WHERE status = 'paid'
AND transactions.payed_at > (now() - interval '1 month')
AND date_part('month', transactions.payed_at) = date_part('month', CURRENT_DATE)
GROUP BY transactions.origin
""").get()
            let salesThisMonthQuery = try await psql.simpleQuery(
"""
SELECT to_char(date(transactions.created_at),'Mon') AS _month, SUM(I.total) as sales_month
FROM transactions
INNER JOIN transaction_items AS I ON transactions.id = I.transaction_id
INNER JOIN product_variants AS V ON I.product_variant_id = V.id
WHERE status = 'paid'
AND transactions.payed_at > (now() - interval '1 month')
AND date_part('month', transactions.payed_at) = date_part('month', CURRENT_DATE)
GROUP BY _month
""").get()
            let salesByProductQuery = try await psql.simpleQuery(
"""
SELECT PP.title as title, SUM(I.total) as sales_month
FROM transactions
INNER JOIN transaction_items AS I ON transactions.id = I.transaction_id
INNER JOIN product_variants AS V ON I.product_variant_id = V.id
INNER JOIN products AS PP ON V.product_id = PP.id
WHERE status = 'paid'
AND transactions.payed_at > (now() - interval '1 year')
GROUP BY title
""").get()
            
            let salesByMonth = try salesByMonthQuery.compactMap { r -> OrderStats.Sale? in
                // Get the month name based on the month number
                let row = PostgresRandomAccessRow(r)
                guard let month = Int(try row["_month"].decode(String.self)) else {
                    return nil
                }
                
                let calendar = Calendar.current
                let monthNumber = calendar.shortMonthSymbols[month - 1]
                
                let cost = try row["cost"].decode(Double.self)
                let sales = try row["sales"].decode(Double.self)
                let count = try row["count"].decode(Int.self)
                
                return OrderStats.Sale(
                    name: monthNumber,
                    value: count,
                    sales: Int(sales),
                    origin: nil,
                    cost: Int(cost))
            }
            let salesBySource = try salesBySourceQuery.map { r -> OrderStats.Sale in
                let row = PostgresRandomAccessRow(r)
                let origin = try row["origin"].decode(String.self)
                let sales = try row["sum"].decode(Double.self)
                
                return OrderStats.Sale(
                    name: origin,
                    value: Int(sales),
                    sales: nil,
                    origin: .init(rawValue: origin))
            }
            let salesThisMonth = try salesThisMonthQuery.map { r -> (String, Int) in
                let row = PostgresRandomAccessRow(r)
                let month = try row["_month"].decode(String.self)
                let sales = try row["sales_month"].decode(Double.self)
                
                return (month, Int(sales))
            }.first ?? ("N/A", 0)
            let salesByProduct = try salesByProductQuery.map { r -> OrderStats.Sale in
                let row = PostgresRandomAccessRow(r)
                let title = try row["title"].decode(String.self)
                let sales = try row["sales_month"].decode(Double.self)
                
                return OrderStats.Sale(
                    name: title,
                    value: Int(sales),
                    sales: nil,
                    origin: nil)
            }
            
            return OrderStats(
                salesByProduct: salesByProduct,
                salesByMonth: salesByMonth,
                salesThisMonth: salesThisMonth.1,
                salesMonthTitle: salesThisMonth.0,
                salesBySource: salesBySource,
                lastSales: try await Transaction.query(on: req.db)
                    .filter(\.$status == .paid)
                    .sort(\.$payedAt, .descending)
                    .limit(14)
                    .all()
                    .asyncMap { try await $0.asPublic(on: req.db) }
            )
        }

        throw Abort(.internalServerError)
    }
}
