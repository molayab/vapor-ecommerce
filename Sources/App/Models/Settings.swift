import Fluent
import Vapor

struct Settings: Content {
    var siteName: String
    var siteDescription: String
    var siteUrl: String
    var analyticsProvider: AnalyticsProvider.Configuration
}

extension Settings {
    enum AnalyticsProvider: String, CaseIterable {
        case posthog
    }
}


extension Settings.AnalyticsProvider {
    struct Configuration: Content {
        var pkKey: String
        var apiKey: String
        var host: String
        var projectId: String
    }
    
    var configuration: Configuration {
        switch self {
        case .posthog:
            return Configuration(
                pkKey: Environment.get("POSTHOG_PK_KEY") ?? "",
                apiKey: Environment.get("POSTHOG_API_KEY") ?? "",
                host: Environment.get("POSTHOG_HOST") ?? "",
                projectId: Environment.get("POSTHOG_PROJECT_ID") ?? "")
        }
    }
}
