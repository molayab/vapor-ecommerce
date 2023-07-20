import Vapor
import Redis
import Fluent

struct AuthenticationController: RouteCollection {
    private let maxAttemptsUntilTemporalBlock = 3
    private let redisAuthenticationAttemptKey = "username"

    func boot(routes: RoutesBuilder) throws {
        routes.get("login", use: loginView)
        
        let authenticator = routes.grouped(User.credentialsAuthenticator())
        authenticator.post("login", use: login)
        
        let protected = routes.grouped(
            UserSessionAuthenticator(),
            User.redirectMiddleware(path: "/login?e=\("401: Unauthorized".base64String())"))
        protected.get("logout", use: logout)
    }
    
    func loginView(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("authentication/login", [
            "error": try? req.query.get(String.self, at: "e").fromBase64()
        ])
    }
    
    func login(req: Request) async throws -> Response {
        let attempts = try await getAttempts(req: req)
        guard attempts < maxAttemptsUntilTemporalBlock  else {
            try await recordAttempt(req: req)
            return req.redirect(to: "/login?e=\("429: Too many requests".base64String())")
        }

        do {
            let user = try req.auth.require(User.self)
            guard user.isActive else {
                return req.redirect(to: "/login?e=\("User is not activated".base64String())")
            }

            var unauthorizedAttempt = try await UnauthorizedAttempt.query(on: req.db)
                .filter(\.$user.$id == user.requireID())
                .all()

            for attempt in unauthorizedAttempt.filter({ $0.expiresAt < Date() }) {
                try await attempt.delete(on: req.db)
                unauthorizedAttempt.removeAll(where: { $0.id == attempt.id })
            }

            if unauthorizedAttempt.isEmpty {
                req.session.authenticate(user)
                return req.redirect(to: "/")
            } else if let last = unauthorizedAttempt.last {
                return req.redirect(to: "/login?e=\("Blocked user until \(last.expiresAt.formatted())".base64String())")
            } else {
                throw Abort(.tooManyRequests)
            }
        } catch let error as AbortError where error.status == .unauthorized {
            try await recordAttempt(req: req)
        } catch { }

        return req.redirect(to: "/login?e=\("401: Unauthorized".base64String())")
    }
    
    func logout(req: Request) throws -> Response {
        req.auth.logout(User.self)
        return req.redirect(to: "/")
    }

    private func getAttempts(req: Request) async throws -> Int {
        return try await withCheckedThrowingContinuation { next in
            do {
                let key = try req.content.get(String.self, at: redisAuthenticationAttemptKey)
                let attempts = try req.redis.get(.init(key), as: Int.self).wait() ?? 0
                next.resume(returning: attempts)
            } catch {
                next.resume(throwing: error)
            }
        }
    }

    private func recordAttempt(req: Request) async throws {
        let attempts = try await getAttempts(req: req)

        try await withCheckedThrowingContinuation { next in
            do {
                let key = try req.content.get(String.self, at: redisAuthenticationAttemptKey)
                try req.redis.set(.init(key), to: attempts + 1).wait()

                // Set a TTL for the unauthorized attempts
                _ = try req.redis.expire(.init(key), after: .seconds(60 * 10)).wait()

                if attempts > maxAttemptsUntilTemporalBlock {
                    // Record the unauthorized attempt in the persistent database. It will be used for checking automated attacks.
                    let ip = req.headers.first(name: .xForwardedFor) ?? req.remoteAddress?.hostname ?? "unknown"
                    if let user = try User.query(on: req.db).filter(\.$email == key).first().wait() {
                        let userId = try user.requireID()
                        let unauthorizedAttempt = try UnauthorizedAttempt(
                            userId: userId,
                            ipAddress: ip,
                            expiresAt: Date()
                                .addingTimeInterval(60 * 15 * TimeInterval(attempts - maxAttemptsUntilTemporalBlock)))
                        
                        try unauthorizedAttempt.save(on: req.db).wait()
                    }
                }
                
                next.resume()
            } catch {
                next.resume(throwing: error)
            }
        }
    }
}

extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self.replacingOccurrences(of: "_", with: "="), options: Data.Base64DecodingOptions(rawValue: 0)) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}