import Vapor

enum Currency: String {
    case COP
    case USD
}

enum GatewayResponse {
    case paid
    case inProgress
    case failed
}

enum GatewayError: Error {
    case canceled
    case expired
    case declined
}

protocol PaymentGateway {
    var fee: Double { get }
    var fixedFee: Double { get }
    
    /// Calls to the API for the provider to make a payment
    func pay(transaction: Transaction.Public, req: Request) async throws -> Response
    
    /// Asks the provider for the status of the payment
    func checkForStatus() async throws -> Result<GatewayResponse, GatewayError>
}

