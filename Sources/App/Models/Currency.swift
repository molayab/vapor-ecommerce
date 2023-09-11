import Vapor
import Fluent

enum Currency: String, Codable, CaseIterable {
    case COP
    case USD
    
    /// This is used for special cases, transactions HAVE TO BE in
    /// a real currency, but sometimes system will use a fake currency
    ///
    /// DO NOT USE DIRECTLY!!!
    ///
    case unknown
}
