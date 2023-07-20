@testable import App
import XCTVapor

final class AuthTests: XCTestCase {
    lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    
    func testLogoutFailure() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        try app.test(.GET, "logout", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
    func testLogoutSuccess() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        let user = try User(name: "Test", password: "password", email: "test@test.com")
        try await user.save(on: app.db)
        
        let auth = try user.generateToken()
        try await auth.save(on: app.db)
        
        try app.test(.GET, "logout", beforeRequest: { res in
            res.headers.add(name: .authorization, value: "Bearer \(auth.token)")
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }
    
    func testLoginFailure() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        try app.test(.POST, "login", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
    func testLoginSuccess() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        let user = try User(name: "Test", password: "password", email: "test@test.com")
        try await user.save(on: app.db)
        
        try app.test(.POST, "login", beforeRequest: { req in
            let token = "test@test.com:password".data(using: .utf8)!.base64EncodedString()
            req.headers.add(name: .authorization, value: "Basic \(token)")
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let model = try decoder.decode(Auth.self, from: res.body)
            XCTAssertEqual(model.$user.id, try user.requireID())
            XCTAssertEqual(model.token.count, 64)
        })
    }
    
    func testMeFailure() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        try app.test(.GET, "me", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
    func testMeSuccess() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        let user = try User(name: "Test", password: "password", email: "test@test.com")
        try await user.save(on: app.db)
        let auth = try user.generateToken()
        try await auth.save(on: app.db)
        
        try app.test(.GET, "me", beforeRequest: { req in
            req.headers.add(name: .authorization, value: "Bearer \(auth.token)")
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let model = try decoder.decode(User.Public.self, from: res.body)
            XCTAssertEqual(model.id, try user.requireID())
        })
    }
    
    func testAuthsFailure() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        try app.test(.GET, "auths", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
    func testAuthsSuccess() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        let user = try User(name: "Test", password: "password", email: "test@test.com")
        try await user.save(on: app.db)
        let auth = try user.generateToken()
        try await auth.save(on: app.db)
        let auth2 = try user.generateToken()
        try await auth2.save(on: app.db)
        
        try app.test(.GET, "auths", beforeRequest: { req in
            req.headers.add(name: .authorization, value: "Bearer \(auth.token)")
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let model = try decoder.decode([Auth].self, from: res.body)
            XCTAssertEqual(model.count, 2)
        })
    }
    
    func testAuthFailureForUnsupportedRoles() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        let user = try User(name: "Test", password: "password", email: "test@test.com")
        try await user.save(on: app.db)
        
        try app.test(.POST, "login", beforeRequest: { req in
            let token = "test@test.com:password".data(using: .utf8)!.base64EncodedString()
            req.headers.add(name: .authorization, value: "Basic \(token)")
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
}
