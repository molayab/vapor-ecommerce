import Vapor
import Fluent
import Queues

/// A scheduled job that runs every day at 00:00
struct CostShedulerJob: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        // Fetch all costs
        let costs = try await Cost.query(on: context.application.db).all()

        // Check for recurring costs
        try await withThrowingTaskGroup(of: Void.self, body: { group in
            for cost in costs {
                group.addTask {
                    try await cost.checkForRecurringCosts(on: context.application.db)
                }
            }

            try await group.waitForAll()
        })
    }
}
