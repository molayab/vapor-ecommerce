import NIOSSL
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Vapor
import Redis
import CSRF
import JWT
import Gatekeeper
import QueuesRedisDriver

/// Site domain
let kSiteDomain = Environment.get("SITE_DOMAIN") ?? "http://localhost:8080"

/// Allowed origins
let kAllowedOrigins = Environment.get("ALLOWED_ORIGINS")?
    .split(separator: ",")
    .map { String($0) } ?? ["http://cms.localhost"]

/// JWT signer key
let kJWTSignerKey = Environment.get("JWT_SIGNER_KEY") ?? "secret"

/// Payment gateways available
enum GatewayType: String, CaseIterable, Content {
    case wompi
    
    // Add more gateways here
    
    var gateway: PaymentGateway {
        switch self {
        case .wompi:
            return Wompi()
        }
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
    app.commands.use(RoleCommand(), as: "roles")
    
    app.routes.defaultMaxBodySize = "20mb"
    app.jwt.signers.use(.hs256(key: kJWTSignerKey))
    app.redis.configuration = try RedisConfiguration(hostname: "redis")
    app.caches.use(.redis)
    if let configuration = app.redis.configuration {
        app.queues.use(.redis(configuration))
        app.queues.schedule(CostShedulerJob()).daily().at(.midnight)
    }
    
    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
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
    app.migrations.add(Address.CreateMigration())
    app.migrations.add(ProductVariant.CreateMigration())
    app.migrations.add(ProductReview.CreateMigration())
    app.migrations.add(ProductQuestion.CreateMigration())
    app.migrations.add(ProductImage.CreateMigration())
    app.migrations.add(Transaction.CreateMigration())
    app.migrations.add(TransactionItem.CreateMigration())
    app.migrations.add(Cost.CreateMigration())
    app.migrations.add(Finance.CreateMigration())
    app.migrations.add(Sale.CreateMigration())
    try await app.autoMigrate()
    
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .any(kAllowedOrigins),
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
    app.middleware.use(cors, at: .beginning)
    app.middleware.use(GatekeeperMiddleware(config: .init(maxRequests: 30, per: .minute)))
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // app.middleware.use(CSRF())
    
    try routes(app)
}

extension PageMetadata {
    var pages: [Int] {
        guard page <= pageCount else {
            return []
        }
        
        var pages: [Int] = []
        var index: Int = 0
        
        for i in max(0, page - 5)..<pageCount {
            if index == 9 {
                break
            }
            
            pages.append(i + 1)
            index += 1
        }
        
        return pages
    }
}
