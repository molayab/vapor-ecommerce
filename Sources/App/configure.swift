import NIOSSL
import NIO
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Vapor
import Redis
import JWT
import Gatekeeper
import QueuesRedisDriver

// Application persistent settings
var settings: Settings!

// configures your application
public func configure(_ app: Application) async throws {
    // create default settings if not exist
    let settingsPath = app.directory.workingDirectory + "/settings.json"

    // load settings
    let fileHandle = try NIOFileHandle(path: settingsPath)
    let fileRegion = try FileRegion(fileHandle: fileHandle)

    let result = try await app.fileio.read(
        fileRegion: fileRegion,
        allocator: ByteBufferAllocator(),
        eventLoop: app.eventLoopGroup.next()).get()
    try fileHandle.close()

    settings = try ContentConfiguration
        .default()
        .requireDecoder(for: .json)
        .decode(Settings.self,
                from: result,
                headers: .init())

    app.commands.use(UserCommand(), as: "users")
    app.commands.use(ProductCommand(), as: "products")
    app.commands.use(RoleCommand(), as: "roles")

    app.routes.defaultMaxBodySize = "100mb"
    app.jwt.signers.use(.hs256(key: settings.secrets.jwt.signerKey))
    app.redis.configuration = try RedisConfiguration(
        hostname: settings.secrets.redis.resolveHostname(),
        pool: .init(
        connectionRetryTimeout: .seconds(60)))

    app.caches.use(.redis)
    app.gatekeeper.config = .init(
        maxRequests: settings.gatekeeper.maxRequestsPerMinute,
        per: .minute)

    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        app.databases.use(.postgres(configuration: SQLPostgresConfiguration(
            hostname: settings.secrets.postgres.hostname,
            port: settings.secrets.postgres.port ?? SQLPostgresConfiguration.ianaPortNumber,
            username: settings.secrets.postgres.username,
            password: settings.secrets.postgres.password,
            database: settings.secrets.postgres.database,
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
    app.migrations.add(ProductVariant.AddTimestampsMigration())
    app.migrations.add(User.AddDeleteField())
    app.migrations.add(TransactionItem.AddTimestampsMigration())
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
    app.middleware.use(GatekeeperMiddleware(
        config: .init(
            maxRequests: settings.gatekeeper.maxRequestsPerMinute,
            per: .minute)))
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    if let configuration = app.redis.configuration {
        var logger = app.logger
        logger.logLevel = .error

        app.queues.configuration = .init(logger: logger)
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

    app.webSocket("notifications") { req, ws in 
        _webSocketNotificationsHandler = ws
        ws.onText { ws, text in
            req.logger.notice("ws received: \(text)")
        }
    }

    try routes(app)
}

private var _webSocketNotificationsHandler: WebSocket?
extension Application {
    func notifyMessage(_ message: String) async {
        guard let ws = _webSocketNotificationsHandler else {
            return
        }

        try? await ws.send(message)
    }
}

extension Request {
    func notifyMessage(_ message: String) async {
        await application.notifyMessage(message)
    }
}