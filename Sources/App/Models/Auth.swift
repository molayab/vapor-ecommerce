import Vapor
import Redis
import JWT

struct Auth: Authenticatable, JWTPayload {
    private static var expirationTime: TimeInterval = { 60 * 15 }()

    var refreshToken = (UUID().uuidString + [UInt8].random(count: 16).base64).base64String()
    var expiration: ExpirationClaim
    var userId: UUID
    
    static func refresh(in req: Request, token: String) async throws -> Auth {
        let user: User = try await withUnsafeThrowingContinuation({ next in
            let key = RedisKey(token)
            
            req.redis.get(key).whenComplete { response in
                switch response {
                case .failure(let error):
                    return next.resume(throwing: error)
                case .success(let content):
                    guard let content = content.string else {
                        return next.resume(throwing: Abort(.unauthorized))
                    }
                    guard let userId = UUID(uuidString: content) else {
                        return next.resume(throwing: Abort(.internalServerError))
                    }
                    
                    req.redis.delete(key).whenComplete { _ in }
                    let user = User.find(userId, on: req.db)
                    user.whenSuccess { user in
                        guard let user = user else {
                            return next.resume(throwing: Abort(.internalServerError))
                        }
                        
                        return next.resume(returning: user)
                    }
                }
            }
        })
        
        return try await Auth(forRequest: req, user: user)
    }
    
    init(forRequest req: Request, user: User) async throws {
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(Self.expirationTime))
        self.userId = try user.requireID()
        
        try await self.storeRefreshToken(
            in: req,
            token: self.refreshToken)
    }
    
    func asPublic(on req: Request) async throws -> Public {
        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.internalServerError)
        }
        
        return Public(
            accessToken: try sign(in: req),
            refreshToken: refreshToken,
            user: try await user.asPublic(on: req.db))
    }
    
    
    func sign(in req: Request) throws -> String {
        return try req.jwt.sign(self)
    }
    
    private func storeRefreshToken(in req: Request, token: String) async throws {
        return try await withUnsafeThrowingContinuation({ next in
            let key = RedisKey(token)
            
            req.redis.setex(
                key,
                to: userId.uuidString,
                expirationInSeconds: 60 * 60 * 24 * 7 // 7 days
            ).whenComplete { response in
                switch response {
                case .failure(let error):
                    return next.resume(throwing: error)
                case .success:
                    return next.resume(returning: ())
                }
            }
        })
    }
    
    func verify(using signer: JWTKit.JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}

extension Auth {
    struct Public: Content {
        var accessToken: String
        var refreshToken: String
        var user: User.Public
    }
}
