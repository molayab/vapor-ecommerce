import NIOSSL
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Vapor
import Redis
import JWT
import Gatekeeper
import QueuesRedisDriver

// Application persistent settings, default values:
var settings = Settings(
    siteName: "Vapor CMS",
    siteDescription: "Vapor CMS is a content management system built with Vapor 4.",
    siteUrl: Environment.get("SITE_DOMAIN") ?? "http://localhost:5173",
    apiUrl: Environment.get("API_DOMAIN") ?? "http://localhost:8080",
    allowedOrigins: [
        "http://cms.localhost",
        "http://localhost:5173",
        "https://app.posthog.com"],
    jwt: Settings.JWT(signerKey: UUID().uuidString.sha256()),
    postHog: Settings.PostHog(
        pkKey: Environment.get("POSTHOG_PK_KEY") ?? "",
        apiKey: Environment.get("POSTHOG_API_KEY") ?? "",
        host: Environment.get("POSTHOG_HOST") ?? "",
        projectId: Environment.get("POSTHOG_PROJECT_ID") ?? ""),
    analyticsProvider: .posthog,
    wompi: Settings.Wompi(
        mode: .test,
        test: Settings.Wompi.Configuration(
            publicKey: Environment.get("WOMPI_TEST_PUBLIC_KEY") ?? "",
            privateKey: Environment.get("WOMPI_TEST_PRIVATE_KEY") ?? "",
            eventsKey: Environment.get("WOMPI_TEST_EVENTS_KEY") ?? "",
            integrityKey: Environment.get("WOMPI_TEST_INTEGRITY_KEY") ?? ""),
        prod: Settings.Wompi.Configuration(
            publicKey: Environment.get("WOMPI_PUBLIC_KEY") ?? "",
            privateKey: Environment.get("WOMPI_PRIVATE_KEY") ?? "",
            eventsKey: Environment.get("WOMPI_EVENTS_KEY") ?? "",
            integrityKey: Environment.get("WOMPI_INTEGRITY_KEY") ?? ""),
        costs: Settings.Wompi.Costs(
            currency: .COP,
            fixed: 500,
            fee: 0.03)))

// configures your application
public func configure(_ app: Application) async throws {
    // create default settings if not exist
    let settingsPath = app.directory.workingDirectory + "/settings.json"
    if !FileManager.default.fileExists(atPath: settingsPath) {
        FileManager
            .default
            .createFile(
                atPath: settingsPath,
                contents: try JSONEncoder()
                    .encode(settings))
        
        app.logger.info("Created default settings.json file")
    }
    
    // load settings
    let data = try Data(contentsOf: URL(fileURLWithPath: settingsPath))
    settings = try JSONDecoder().decode(Settings.self, from: data)
    
    app.commands.use(UserCommand(), as: "users")
    app.commands.use(ProductCommand(), as: "products")
    app.commands.use(RoleCommand(), as: "roles")
    
    app.routes.defaultMaxBodySize = "256mb"
    app.jwt.signers.use(.hs256(key: settings.jwt.signerKey))
    app.redis.configuration = try RedisConfiguration(hostname: "redis", pool: .init(
        connectionRetryTimeout: .seconds(60)))
    
    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        app.databases.use(.postgres(configuration: SQLPostgresConfiguration(
            hostname: Environment.get("DATABASE_HOST") ?? "db",
            port: Environment.get("DATABASE_PORT")
                .flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
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
    app.migrations.add(Transaction.CreateMigration())
    app.migrations.add(TransactionItem.CreateMigration())
    app.migrations.add(Cost.CreateMigration())
    app.migrations.add(Finance.CreateMigration())
    app.migrations.add(Sale.CreateMigration())
    try await app.autoMigrate()
    
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .any(settings.allowedOrigins),
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [
            .accept,
            .authorization,
            .contentType,
            .origin,
            .xRequestedWith,
            .userAgent,
            .xForwardedFor,
            .xForwardedHost,
            .xForwardedProto,
            .init("x-csrf-token")
        ],
        allowCredentials: true,
        cacheExpiration: 600
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    app.middleware.use(cors, at: .beginning)
    app.middleware.use(GatekeeperMiddleware(config: .init(maxRequests: 100, per: .minute)))
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    if let configuration = app.redis.configuration {
        app.queues.use(.redis(configuration))
        app.queues.schedule(CostShedulerJob()).daily().at(.midnight)
        app.queues.add(ImageResizerJob())
        
        try app.queues.startInProcessJobs(on: .default)
        try app.queues.startScheduledJobs()
        app.logger.info("Redis is configured")
        app.logger.info("Queues are configured")
    } else {
        app.logger.error("Redis configuration not found")
    }
    
    app.caches.use(.redis)
    try routes(app)
}
