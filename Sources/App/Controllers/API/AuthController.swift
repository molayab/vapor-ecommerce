import Vapor
import Fluent

/**
    # Auth Controller
    This controller handles all the routes related to authentication. The login process requires the
    Basic Authorization header to be set with the user's email and password, if the user is authenticated then,
    a new Beamer token is created and returned.
 
    ## Routes
    - POST `/login` - Creates a new auth token
        - Basic Authorization Header
            - username: String
            - password: String
    - GET `/me` - Returns the current user
    - GET `/logout` - Deletes the current auth token
    - GET `/auths` - Returns all auth tokens for the current user
 */
struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(Auth.authenticator())
        let password = routes.grouped(User.authenticator())
        
        password.post("login", use: create)
        protected.get("me", use: me)
        protected.get("logout", use: delete)
        protected.get("auths", use: index)
    }

    private func create(req: Request) async throws -> Auth {
        let user = try req.auth.require(User.self)
        /*guard [.admin, .pos, .user].contains(user.roles.map { $0.role }) else {
            throw Abort(.unauthorized)
        }*/
        
        let token = try user.generateToken()
        try await token.save(on: req.db)
        return token
    }
    
    private func index(req: Request) async throws -> [Auth] {
        let user = try req.auth.require(User.self)
        let auths = try await Auth.query(on: req.db).filter(\.$user.$id == user.requireID()).all()
        return auths
    }
    
    private func me(req: Request) async throws -> User.Public {
        return try await req.auth.require(User.self).asPublic(on: req.db)
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        if let token = req.headers.bearerAuthorization?.token {
            let auth = try await Auth.query(on: req.db).filter(\.$token == token).first()
            
            if auth?.$user.id == user.id {
                try await auth?.delete(on: req.db)
                return .ok
            }
            
            return .unauthorized
        }
        
        return .badRequest
    }
}
