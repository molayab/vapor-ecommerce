import Vapor
import Fluent
import Queues

struct TransactionCheckerJob: AsyncScheduledJob, AsyncJob {
    func dequeue(_ context: QueueContext, _ payload: UUID) async throws {
        try await exec(context: context, payload: payload)
    }
    
    func run(context: QueueContext) async throws {
        try await exec(context: context)
    }
    
    private func exec(context: QueueContext, payload: UUID? = nil) async throws {
        // Fetch all transactions
        if let payload {
            try await Transaction
                .query(on: context.application.db)
                .filter(\.$id == payload)
                .chunk(max: 1) { result in
                    task(result: result, context: context)
                }
            
        } else {
            try await Transaction
                .query(on: context.application.db)
                .group(.and) { and in
                    and.filter(\.$status == .paid)
                    and.group(.or) { or in
                        or.filter(\.$currency == .unknown)
                        or.filter(\.$total == 0)
                        or.filter(\.$subtotal == 0)
                    }
                }
                .chunk(max: 1024) { result in
                    task(result: result, context: context)
                }
            }
    }
    
    private func task(result: [Result<Transaction, Error>], context: QueueContext) {
        do {
            for transaction in result {
                switch transaction {
                case .success(let transaction):
                    let items = transaction.$items.get(
                        on: context.application.db)
                    items.whenSuccess { items in
                            var total: Double = 0
                            
                            for item in items {
                                total += item.price * Double(item.quantity)
                            }
                            
                            // Apply discount
                            let discount = transaction.$discount.get(on: context.application.db)
                            discount.whenSuccess { discount in
                                
                                if let discount = discount {
                                    switch discount.type {
                                    case .fixed:
                                        total -= discount.discount
                                    case .percentage:
                                        total -= total * discount.discount
                                    case .fixedNoCharge:
                                        break
                                    }
                                }
                                
                                transaction.currency = .COP
                                transaction.total = total + (total * transaction.tax)
                                transaction.subtotal = total
                                transaction.update(on: context.application.db).whenSuccess {
                                    context.logger.info("[TransactionCheckerJob][INFO] Transaction updated")
                                }
                            }
                        }
                case .failure(let error):
                    context.logger.error("[TransactionCheckerJob][ERROR] \(error)")
                }
            }
        }
    }
}
