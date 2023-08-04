import NIOSSL
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Vapor
import Redis
import CSRF
import JWT
extension Application {
    /// Configures the allowed CORS origins for the application.
    var allowedOriginURLs: [String] {
        [
            "http://cms.localhost",
        ]
    }
}
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
    app.commands.use(UserCommand(), as: "users")
    app.commands.use(ProductCommand(), as: "products")

    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // set post maximum size to 20mb
    app.routes.defaultMaxBodySize = "20mb"
    
    // set JWT secret key
    app.jwt.signers.use(.hs256(key: Environment.get("JWT_SIGNER_KEY") ?? "secret"))

    // docker run -d --name redis-stack -p 6379:6379 -p 8001:8001 redis/redis-stack:latest
    app.redis.configuration = try RedisConfiguration(hostname: "redis")
    app.sessions.use(.redis(delegate: CustomRedisSessionsDelegate()))
    
    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        // docker run --name vapor_postgres -e POSTGRES_PASSWORD="password123" -e POSTGRES_USER="vapor" -e POSTGRES_DB="vapor_database" -p 5432:5432 postgres
        app.databases.use(.postgres(configuration: SQLPostgresConfiguration(
            hostname: Environment.get("DATABASE_HOST") ?? "db",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
            database: Environment.get("DATABASE_NAME") ?? "vapor_database",
            tls: .prefer(try .init(configuration: .clientDefault)))
        ), as: .psql)
    }

    app.migrations.add(User.CreateMigration())
    app.migrations.add(Category.CreateMigration())
    app.migrations.add(Product.CreateMigration())
    app.migrations.add(Role.CreateMigration())
    app.migrations.add(Country.CreateMigration())
    app.migrations.add(State.CreateMigration())
    app.migrations.add(Address.CreateMigration())
    app.migrations.add(ProductVariant.CreateMigration())
    app.migrations.add(ProductReview.CreateMigration())
    app.migrations.add(ProductQuestion.CreateMigration())
    app.migrations.add(ProductImage.CreateMigration())
    try await app.autoMigrate()
    
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .any(app.allowedOriginURLs),
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [
            .accept,
            .authorization,
            .contentType,
            .origin,
            .xRequestedWith,
            .userAgent
        ],
        allowCredentials: true,
        cacheExpiration: 600
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    // cors middleware should come before default error middleware using `at: .beginning`
    app.middleware.use(cors, at: .beginning)
    app.middleware.use(app.sessions.middleware)
    // app.middleware.use(CSRF())
    
    try routes(app)
}
