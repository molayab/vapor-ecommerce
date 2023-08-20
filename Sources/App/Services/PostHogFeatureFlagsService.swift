import Fluent
import Vapor

struct PostHogFeatureFlag: Content {
    var id: Int
    var key: String
    var active: Bool
}

struct PostHogFeatureFlags: Content {
    var results: [PostHogFeatureFlag]
}

struct PostHogFeatureFlagsService {
    let apiKey = "phx_869bvDbbPMzJpySrNar1naTbur79rAyIjaYuiOrdUyI"
    let request: Request
    
    enum Flag: String, Codable, CaseIterable {
        case posEnabled = "cms_pos_enabled"
        case loginEnabled = "cms_login_enabled"
        case autocaptureEnabled = "cms_autocapture_enabled"
        case frontendEnabled = "frontend_site_enabled"
        case paymentWompiEnabled = "cms_payment_wompi_enabled"
        
        var key: String {
            return rawValue
        }
    }
    
    func isAllowed(_ flag: Flag) async throws -> Bool {
        guard let featureFlags = try await cachedFlags() else {
            try await fetchRemoteFlags()
            return try await isAllowed(flag)
        }
        guard let featureFlag = featureFlags
                .results
                .first(where: { $0.key == flag.key }) else {
            return true
        }
        
        return featureFlag.active
    }
    
    func getAllFeatureFlags() async throws -> PostHogFeatureFlags? {
        try await fetchRemoteFlags()
        return try await cachedFlags()
    }
    
    func toggleFeatureFlag(_ flag: Flag) async throws -> PostHogFeatureFlags? {
        try await fetchRemoteFlags()
        guard let featureFlags = try await cachedFlags()?
            .results
            .first(where: { $0.key == flag.key }) else {
                return nil
        }
        
        let uri = URI("https://app.posthog.com/api/projects/34006/feature_flags/\(featureFlags.id)")
        let response = try await request
            .client
            .patch(
                uri,
                headers: [
                    "Authorization": "Bearer \(apiKey)",
                    "Content-Type": "application/x-www-form-urlencoded"
                ],
                content: [
                    "active": !featureFlags.active
                ])
        
        request.logger.info("\(response.status)")
        
        
        return try await getAllFeatureFlags()
    }
    
    
    private func fetchRemoteFlags() async throws {
        let uri = URI("https://app.posthog.com/api/projects/34006/feature_flags?limit=1000")
        let response = try await request
            .client
            .get(uri, headers: ["Authorization": "Bearer \(apiKey)"])
        
        guard response.status == .ok else { return }
        
        let featureFlags = try response.content.decode(PostHogFeatureFlags.self)
        try await request.cache.set("featureFlags", to: featureFlags, expiresIn: .seconds(120))
    }
    
    private func cachedFlags() async throws -> PostHogFeatureFlags? {
        return try await request.cache.get(
                "featureFlags",
                as: PostHogFeatureFlags.self)
    }
}

extension Request {
    var featureFlags: PostHogFeatureFlagsService {
        return PostHogFeatureFlagsService(request: self)
    }
    
    func ensureFeatureEnabled(_ flag: PostHogFeatureFlagsService.Flag) async throws {
        guard try await featureFlags.isAllowed(flag) else {
            throw Abort(.forbidden, reason: "Feature not enabled")
        }
    }
}
