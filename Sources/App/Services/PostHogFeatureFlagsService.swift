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
    let hostname: String
    let apiKey: String
    let appId: String
    let request: Request

    enum Flag: String, Codable, CaseIterable {
        case posEnabled = "cms_pos_enabled"
        case loginEnabled = "cms_login_enabled"
        case autocaptureEnabled = "cms_autocapture_enabled"
        case frontendEnabled = "frontend_site_enabled"
        case paymentWompiEnabled = "cms_payment_wompi_enabled"

        var key: String { rawValue }
    }

    func isAllowed(_ flag: Flag, alreadyTried: Bool = false) async throws -> Bool {
        guard let featureFlags = try await cachedFlags() else {
            try await fetchRemoteFlags()
            return try await isAllowed(flag, alreadyTried: true)
        }
        guard let featureFlag = featureFlags
                .results
                .first(where: { $0.key == flag.key }) else {
            return true
        }

        guard !alreadyTried else {
            throw Abort(.internalServerError)
        }

        return featureFlag.active
    }

    /**
     * Fetches the feature flags from the cache. It will fetch the remote
     * flags if the cache is empty.
     */
    func getAllFeatureFlags(alreadyTried: Bool = false) async throws -> PostHogFeatureFlags? {
        guard let featureFlags = try await cachedFlags() else {
            try await fetchRemoteFlags()
            return try await getAllFeatureFlags(alreadyTried: true)
        }

        guard !alreadyTried else {
            throw Abort(.internalServerError)
        }

        return featureFlags
    }

    /**
     * Toggle a feature flag.
     */
    func toggleFeatureFlag(_ flag: Flag) async throws -> PostHogFeatureFlags? {
        try await fetchRemoteFlags()
        guard let featureFlags = try await cachedFlags()?
            .results
            .first(where: { $0.key == flag.key }) else {
                return nil
        }

        let uri = URI("\(hostname)/api/projects/\(appId)/feature_flags/\(featureFlags.id)")
        let response = try await request
            .client
            .patch(uri,
                headers: [
                    "Authorization": "Bearer \(apiKey)",
                    "Content-Type": "application/x-www-form-urlencoded"],
                content: [
                    "active": !featureFlags.active
                ])

        request.logger.info("[PostHogFeatureFlagsService] Toggle: \(response.status)")
        return try await getAllFeatureFlags()
    }

    private func fetchRemoteFlags() async throws {
        // Warning: this will only fetch the first 1000 flags
        let uri = URI("\(hostname)/api/projects/\(appId)/feature_flags?limit=1000")
        let response = try await request
            .client
            .get(uri, headers: ["Authorization": "Bearer \(apiKey)"])

        request.logger.info("[PostHogFeatureFlagsService] Fetch: \(response.status)")

        guard response.status == .ok else { return }
        let featureFlags = try response
            .content
            .decode(PostHogFeatureFlags.self)
        try await request.cache.set(
            "featureFlags",
            to: featureFlags,
            expiresIn: .minutes(15))

        request.logger.info("[PostHogFeatureFlagsService] Cached: \(featureFlags)")
    }

    private func cachedFlags() async throws -> PostHogFeatureFlags? {
        request.logger.info("[PostHogFeatureFlagsService] Getting cached flags")
        return try await request.cache.get(
            "featureFlags",
            as: PostHogFeatureFlags.self)
    }
}

extension Request {
    /// A service to interact with PostHog feature flags.
    var featureFlags: PostHogFeatureFlagsService {
        return PostHogFeatureFlagsService(
            hostname: settings.postHog.host,
            apiKey: settings.postHog.pkKey,
            appId: settings.postHog.projectId,
            request: self)
    }

    /**
     * Ensures that a feature flag is enabled, otherwise it will throw an
     * `Abort` error.
     */
    func ensureFeatureEnabled(_ flag: PostHogFeatureFlagsService.Flag) async throws {
        guard try await featureFlags.isAllowed(flag) else {
            throw Abort(.forbidden, reason: "Feature not enabled")
        }
    }
}
