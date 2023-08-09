import Vapor

enum Currency: String {
    case COP
    case USD
}

struct PaymentEvent {
    enum Status {
        case approved
        case inProgress
        case declined
    }
    
    var reference: String
    var status: Status
}

protocol PaymentGateway {
    var fee: Double { get }
    var fixedFee: Double { get }
    
    /// Calls to the API for the provider to make a payment
    func pay(transaction: Transaction.Public, req: Request) async throws -> Response
    
    /// Asks the provider for the status of the payment
    func checkEvent(for req: Request) async throws -> PaymentEvent
}

