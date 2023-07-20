import Vapor
import Fluent

final class Cart: Model, Content {
    static let schema = "carts"
    
    @ID(key: .id)
    var id: UUID?
    
}
