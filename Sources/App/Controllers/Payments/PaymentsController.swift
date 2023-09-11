import Vapor
import Fluent

struct PaymentsController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        let payments = routes.grouped("transactions", "payment")
        payments.get("callback", ":provider", use: callback)
        payments.get("pay", ":provider", ":transactionId", use: pay)
    }

    private func pay(req: Request) async throws -> Response {
        guard let transactionId = req.parameters.get("transactionId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let providerStr = req.parameters.get("provider", as: String.self) else {
            throw Abort(.badRequest)
        }
        guard let provider = Settings.PaymentGateway(rawValue: providerStr)?.gateway else {
            throw Abort(.badRequest)
        }
        guard let transaction = try await Transaction.find(transactionId, on: req.db) else {
            throw Abort(.notFound)
        }

        transaction.status = .pending
        transaction.orderdAt = Date()
        try await transaction.save(on: req.db)

        return try await provider.pay(
            transaction: try await transaction.asPublic(request: req),
            req: req)
    }

    private func callback(req: Request) async throws -> Response {
        guard let providerStr = req.parameters.get("provider", as: String.self) else {
            throw Abort(.badRequest)
        }
        guard let provider = Settings.PaymentGateway(rawValue: providerStr)?.gateway else {
            throw Abort(.badRequest)
        }

        let response = try await provider.checkEvent(for: req)
        guard let transactionId = UUID(uuidString: response.reference) else {
            req.logger.error("Invalid transaction id for \(response.reference) in \(provider) callback")
            throw Abort(.badRequest)
        }

        let transaction = try await Transaction.find(transactionId, on: req.db)
        guard let transaction = transaction else {
            req.logger.error("Transaction \(transactionId) not found in \(provider) callback")
            throw Abort(.notFound)
        }

        switch response.status {
        case .approved:
            transaction.status = .paid
        case .declined:
            transaction.status = .declined
        case .inProgress:
            transaction.status = .pending
        }

        try await transaction.save(on: req.db)
        return Response(status: .ok)
    }
}
