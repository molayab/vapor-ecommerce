@testable import App
import XCTVapor

/*final class CategoriesTests: XCTestCase {
    lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    func testDeleteCategoryFailure() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        try app.test(.DELETE, "categories/1", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
        
        let user = try User(name: "Test", password: "password", email: "test@test.com")
        try await user.save(on: app.db)
        let auth = try user.generateToken()
        try await auth.save(on: app.db)
        
        try app.test(.DELETE, "categories/\(UUID().uuidString)", beforeRequest: { req in
            req.headers.add(name: .authorization, value: "Bearer \(auth.token)")
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
        
        let user2 = try User(name: "Test", password: "password", email: "test2@test.com")
        try await user2.save(on: app.db)
        let auth2 = try user2.generateToken()
        try await auth2.save(on: app.db)
        
        try app.test(.DELETE, "categories/1", beforeRequest: { req in
            req.headers.add(name: .authorization, value: "Bearer \(auth2.token)")
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
    func testDeleteCategorySuccess() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        let user = try User(name: "Test", password: "password", email: "test@test.com")
        try await user.save(on: app.db)
        let auth = try user.generateToken()
        try await auth.save(on: app.db)
        let category = App.Category(model: .init(title: "Test", description: "Test Description"))
        try await category.save(on: app.db)
        
        try app.test(.DELETE, "categories/\(category.requireID())", beforeRequest: { req in
            req.headers.add(name: .authorization, value: "Bearer \(auth.token)")
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }
    
    func testCreateCategoryFailure() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        try app.test(.POST, "categories", afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
        
        let user = try User(name: "Test", password: "password", email: "test@test.com")
        try await user.save(on: app.db)
        let auth = try user.generateToken()
        try await auth.save(on: app.db)
        
        try app.test(.POST, "categories", beforeRequest: { req in
            req.headers.add(name: .authorization, value: "Bearer \(auth.token)")
            try req.content.encode(App.Category.Create(title: "Test", description: "Test Description"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized)
        })
    }
    
    func testCreateCategorySuccess() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)
        
        let user = try User(name: "Test", password: "password", email: "test@test.com")
        try await user.save(on: app.db)
        let auth = try user.generateToken()
        try await auth.save(on: app.db)
        
        try app.test(.POST, "categories", beforeRequest: { req in
            req.headers.add(name: .authorization, value: "Bearer \(auth.token)")
            try req.content.encode(App.Category.Create(title: "Test", description: "Test Description"))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            
            let category = try res.content.decode(Category.self)
            XCTAssertEqual(category.title, "Test")
            XCTAssertEqual(category.description, "Test Description")
            XCTAssertNotNil(category.createdAt)
        })
    }
}*/
