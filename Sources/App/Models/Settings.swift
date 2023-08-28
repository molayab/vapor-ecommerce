import Fluent
import Vapor

struct Settings: Content {
    var siteName: String
    var siteDescription: String
    var siteUrl: String
    var apiUrl: String
    var allowedOrigins: [String]
    var jwt: JWT
    var postHog: PostHog
    var analyticsProvider: AnalyticsProvider
    var wompi: Wompi

    func asPublic() -> Public {
        Public(
            siteName: siteName,
            siteDescription: siteDescription,
            siteUrl: siteUrl,
            apiUrl: apiUrl,
            allowedOrigins: allowedOrigins,
            analyticsProvider: analyticsProvider,
            postHog: postHog.asPublic(),
            wompi: wompi.asPublic())
    }

    struct JWT: Content {
        var signerKey: String
    }

    struct PostHog: Content {
        var pkKey: String
        var apiKey: String
        var host: String
        var projectId: String

        func asPublic() -> Public {
            Public(
                apiKey: apiKey,
                host: host,
                projectId: projectId)
        }

        struct Public: Content {
            var apiKey: String
            var host: String
            var projectId: String
        }
    }

    struct Wompi: Content {
        enum Mode: String, Content {
            case test
            case prod
        }
        struct Configuration: Content {
            var publicKey: String
            var privateKey: String
            var eventsKey: String
            var integrityKey: String
        }
        struct Costs: Content {
            var currency: Currency
            var fixed: Int
            var fee: Double
        }
        struct Public: Content {
            var mode: Mode
            var costs: Costs
        }

        var mode: Mode
        var test: Configuration
        var prod: Configuration
        var costs: Costs

        func asPublic() -> Public {
            Public(
                mode: mode,
                costs: costs)
        }

        var configuration: Configuration {
            switch mode {
            case .test:
                return test
            case .prod:
                return prod
            }
        }
    }

    struct Public: Content {
        var siteName: String
        var siteDescription: String
        var siteUrl: String
        var apiUrl: String
        var allowedOrigins: [String]
        var analyticsProvider: AnalyticsProvider
        var postHog: PostHog.Public
        var wompi: Wompi.Public
        var availableCurrencies = Currency.allCases
    }
}

extension Settings {
    enum AnalyticsProvider: String, CaseIterable, Content {
        case posthog
    }
}

extension Settings {
    /// Payment gateways available
    enum PaymentGateway: String, CaseIterable, Content {
        case wompi

        var gateway: PaymentGatewayProtocol {
            switch self {
            case .wompi:
                return WompiService()
            }
        }
    }
}

extension Settings.AnalyticsProvider {
    var configuration: Settings.PostHog {
        switch self {
        case .posthog:
            return settings.postHog
        }
    }
}
