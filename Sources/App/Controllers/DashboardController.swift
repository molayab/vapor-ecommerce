import Vapor
import Fluent
import FluentPostgresDriver

struct DashboardController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        // Public API
        let transactions = routes.grouped("dashboard")
        let requiredAuth = transactions.grouped(
            UserSessionAuthenticator(),
            User.guardMiddleware())
        let unauthorized = requiredAuth.grouped(RoleMiddleware(roles: [.admin, .manager]))
        unauthorized.get("stats", use: stats)
    }

    func index(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("Dashboard/index")
    }

    // swiftlint:disable:next function_body_length
    private func stats(req: Request) async throws -> OrderStats {
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

            let salesByMonth = try salesByMonthQuery.compactMap { rowContext -> OrderStats.Sale? in
                // Get the month name based on the month number
                let row = PostgresRandomAccessRow(rowContext)
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
            let salesBySource = try salesBySourceQuery.map { rowContext -> OrderStats.Sale in
                let row = PostgresRandomAccessRow(rowContext)
                let origin = try row["origin"].decode(String.self)
                let sales = try row["sum"].decode(Double.self)

                return OrderStats.Sale(
                    name: origin,
                    value: Int(sales),
                    sales: nil,
                    origin: .init(rawValue: origin))
            }
            let salesThisMonth = try salesThisMonthQuery.map { rowContext -> (String, Int) in
                let row = PostgresRandomAccessRow(rowContext)
                let month = try row["_month"].decode(String.self)
                let sales = try row["sales_month"].decode(Double.self)

                return (month, Int(sales))
            }.first ?? ("N/A", 0)
            let salesByProduct = try salesByProductQuery.map { rowContext -> OrderStats.Sale in
                let row = PostgresRandomAccessRow(rowContext)
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
