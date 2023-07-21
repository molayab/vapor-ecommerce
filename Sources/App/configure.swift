import NIOSSL
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Vapor
import Leaf
import Redis

import Fakery

struct CustomRedisSessionsDelegate: RedisSessionsDelegate {
    func redis<Client>(_ client: Client, store data: SessionData, with key: RedisKey) -> EventLoopFuture<Void> where Client : RedisClient {
        return client.set(key, toJSON: data).flatMap { _ in
            client.expire(key, after: .hours(24))
        }.map { _ in
            ()
        }
    }

    func redis<Client>(_ client: Client, fetchDataFor key: RedisKey) -> EventLoopFuture<SessionData?> where Client : RedisClient {
        return client.get(key, asJSON: SessionData.self)
    }
}

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // docker run -d --name redis-stack -p 6379:6379 -p 8001:8001 redis/redis-stack:latest
    app.redis.configuration = try RedisConfiguration(hostname: "localhost")
    app.sessions.use(.redis(delegate: CustomRedisSessionsDelegate()))
    
    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        // docker run --name vapor_postgres -e POSTGRES_PASSWORD="password123" -e POSTGRES_USER="vapor" -e POSTGRES_DB="vapor_database" -p 5432:5432 postgres
        app.databases.use(.postgres(configuration: SQLPostgresConfiguration(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor",
            password: Environment.get("DATABASE_PASSWORD") ?? "password123",
            database: Environment.get("DATABASE_NAME") ?? "vapor_database",
            tls: .prefer(try .init(configuration: .clientDefault)))
        ), as: .psql)
    }

    app.migrations.add(User.CreateMigration())
    app.migrations.add(Auth.CreateMigration())
    app.migrations.add(Category.CreateMigration())
    app.migrations.add(Product.CreateMigration())
    app.migrations.add(Role.CreateMigration())
    app.migrations.add(UnauthorizedAttempt.CreateMigration())
    app.migrations.add(Country.CreateMigration())
    app.migrations.add(State.CreateMigration())
    app.migrations.add(Address.CreateMigration())
    try await app.autoMigrate()
    
    // Create root user
    let rootEmail = Environment.get("CMS_ROOT_USER") ?? "root@cms.local"
    if try await app.db.query(User.self).filter(\.$email == rootEmail).first() == nil {
        let rootUser = try User(
            create: .init(
                name: Environment.get("CMS_ROOT_NAME") ?? "Root User",
                kind: .employee,
                password: Environment.get("CMS_ROOT_PASSWORD") ?? "password",
                email: rootEmail,
                role: [.admin],
                isActive: true))
        try await rootUser.save(on: app.db)
        let role = Role(role: .admin, userId: try rootUser.requireID())
        try await role.save(on: app.db)
    }
    
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    // cors middleware should come before default error middleware using `at: .beginning`
    app.middleware.use(cors, at: .beginning)
    app.middleware.use(app.sessions.middleware)
    app.views.use(.leaf)
    
    try routes(app)
}
