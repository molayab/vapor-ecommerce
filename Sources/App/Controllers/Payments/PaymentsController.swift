import Vapor
import Fluent

struct PaymentsController: RouteCollection {
    func boot(routes: Vapor.RoutesBuilder) throws {
        let payments = routes.grouped("payments")
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
        guard let provider = GatewayType(rawValue: providerStr)?.gateway else {
            throw Abort(.badRequest)
        }
        guard let transaction = try await Transaction.find(transactionId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try await provider.pay(
            transaction: try await transaction.asPublic(on: req.db),
            req: req)
    }
    
    private func callback(req: Request) async throws -> Response {
        guard let providerStr = req.parameters.get("provider", as: String.self) else {
            throw Abort(.badRequest)
        }
        guard let provider = GatewayType(rawValue: providerStr)?.gateway else {
            throw Abort(.badRequest)
        }
        
        // Validate the request is coming from the provider
        
        // Get the tx reference
        
        // Get the status from the provider
        
        // Update the transaction status
    
        return Response(status: .ok)
    }
}

