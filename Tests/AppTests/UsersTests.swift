@testable import App
import XCTVapor

final class UsersTests: XCTestCase {
    lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    func testRolesSuccess() async throws {
        /*let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        let user = try User(name: "Test", password: "password", email: "test@test.com")
        try await user.save(on: app.db)
        let auth = try user.generateToken()
        try await auth.save(on: app.db)
        
        try app.test(.GET, "users/roles", beforeRequest: { req in
            req.headers.add(name: .authorization, value: "Bearer \(auth.token)")
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let roles = try res.content.decode([Role].self, using: self.decoder)
            XCTAssertEqual(roles.count, 4)
            
            XCTAssertTrue(roles.contains(.admin))
            XCTAssertTrue(roles.contains(.user))
            XCTAssertTrue(roles.contains(.pos))
            XCTAssertTrue(roles.contains(.client))
        })*/
    }
    
}
