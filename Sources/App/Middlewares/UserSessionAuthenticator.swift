import Vapor
import Fluent

struct UserSessionAuthenticator: AsyncSessionAuthenticator  {
    typealias User = App.User
    
    func authenticate(sessionID: String, for request: Request) async throws {
        guard let user = try await User.query(on: request.db).filter(\User.$email == sessionID).first() else {
            throw Abort(.unauthorized)
        }
        
        request.auth.login(user)
    }
}

