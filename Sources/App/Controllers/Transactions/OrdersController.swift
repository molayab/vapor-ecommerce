import Vapor
import Fluent
import FluentSQL

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
        unauthorized.get("variants", ":variantId", use: listTransactionsForVariant)
        unauthorized.get(":id", "items", use: listItemsForTransaction)
        unauthorized.get("all", "metadata", use: allOrdersMetadata)
    }

    /// Private API
    /// GET /transactions/mine
    /// This endpoint is used to retrieve the current user's transactions.
    private func myOrders(req: Request) async throws -> [Transaction.Public] {
        let user = try req.auth.require(User.self)
        return try await Transaction.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .all()
            .asyncMap { try await $0.asPublic(request: req) }
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
    
    /// Restricted API
    /// GET /transactions/all/metadata
    /// This endpoint is used to retrieve all transactions metadata.
    private func allOrdersMetadata(req: Request) async throws -> [String: String] {
        let total = try await Transaction.query(on: req.db).count()
        let pending = try await Transaction.query(on: req.db)
            .filter(\.$status == .pending).count()
        let paid = try await Transaction.query(on: req.db)
            .filter(\.$status == .paid).count()
        let placed = try await Transaction.query(on: req.db)
            .filter(\.$status == .placed).count()
        let totalSales = try await Transaction.query(on: req.db)
            .filter(\.$status == .paid)
            .sum(\.$total) ?? 0
        let canceled = try await Transaction.query(on: req.db)
            .filter(\.$status == .canceled).count()
        
        var totalTaxes: String = ""
        var totalRevenue: String = ""
        
        if let db = req.db as? SQLDatabase,
            let row = try await db.raw("""
SELECT SUM(ABS(subtotal - total)) FROM transactions WHERE status = 'paid'
AND payed_at > (now() - interval '1 year')
""").all().first {
            let totalTaxesInt: Double = try row.decode(column: "sum")
            totalTaxes = String(totalTaxesInt)
        }
        
        if let db = req.db as? SQLDatabase,
            let row = try await db.raw("""
SELECT SUM((transaction_items.price * transaction_items.quantity) - (V.price * transaction_items.quantity))
FROM transaction_items
JOIN transactions AS T ON T.id = transaction_items.transaction_id
JOIN product_variants AS V ON V.id = transaction_items.product_variant_id
WHERE T.status = 'paid'
AND T.payed_at > (now() - interval '1 year')
""").all().first {
            let totalRevenueInt: Double = try row.decode(column: "sum")
            totalRevenue = String(totalRevenueInt)
        }
        
        return [
            "total": String(total),
            "pending": String(pending),
            "paid": String(paid),
            "placed": String(placed),
            "totalSales": String(totalSales),
            "canceled": String(canceled),
            "totalTaxes": totalTaxes,
            "totalRevenue": totalRevenue
        ]
    
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
    /// GET /transactions/variants/:variantId
    /// This endpoint is used to retrieve all transactions for a variant.
    private func listTransactionsForVariant(req: Request) async throws -> [TransactionItem.Public] {
        guard let variantId = req.parameters.get("variantId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let variant = try await ProductVariant.find(variantId, on: req.db) else {
            throw Abort(.notFound)
        }

        let items = try await variant.$transactionItems.get(on: req.db)
        return try await items.asyncMap { try await $0.asPublic(request: req) }
    }

    /// Restricted API
    /// GET /transactions/:id/items
    /// This endpoint is used to retrieve all items for a transaction.
    private func listItemsForTransaction(req: Request) async throws -> [ProductVariant.Public] {
        guard let transactionId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let transaction = try await Transaction.find(transactionId, on: req.db) else {
            throw Abort(.notFound)
        }

        var items: [ProductVariant] = []
        
        for item in try await transaction.$items
            .get(on: req.db) {
            
            if item.quantity > 1 {
                for _ in 1...item.quantity {
                    let variant = try await item.$productVariant.get(on: req.db)
                    
                    items.append(variant)
                }
            } else {
                try await items.append(item.$productVariant.get(on: req.db))
            }
        }
        
        return try await items.asyncMap { item in
            let variant = try await item.asPublic(request: req)
            return ProductVariant.Public(
                id: UUID(),
                product: variant.product,
                name: variant.name,
                price: variant.price,
                salePrice: variant.salePrice,
                sku: variant.sku,
                stock: variant.stock,
                isAvailable: variant.isAvailable,
                images: variant.images,
                tax: variant.tax
            )
        }
    }

}
