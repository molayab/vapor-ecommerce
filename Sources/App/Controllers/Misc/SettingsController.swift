import Fluent
import Vapor
import NIO

struct SettingsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let settings = routes.grouped("settings")

        // Public API
        settings.get(use: getSettings)

        // Restricted API
        let restricted = settings.grouped(
            UserSessionAuthenticator(),
            User.guardMiddleware(),
            RoleMiddleware(roles: [.admin]))
        restricted.get("flags", use: getAllFeatureFlags)
        restricted.patch("flags", ":flag", use: toggleFeatureFlag)
    }

    private func getAllFeatureFlags(req: Request) async throws -> PostHogFeatureFlags {
        guard let flags = try await req.featureFlags.getAllFeatureFlags() else {
            throw Abort(.internalServerError)
        }
        return flags
    }

    private func toggleFeatureFlag(req: Request) async throws -> PostHogFeatureFlags {
        guard let flag = req.parameters.get("flag", as: String.self) else {
            throw Abort(.badRequest)
        }
        guard let flag = PostHogFeatureFlagsService.Flag(rawValue: flag) else {
            throw Abort(.badRequest)
        }
        guard let flags = try await req.featureFlags.toggleFeatureFlag(flag) else {
            throw Abort(.internalServerError)
        }

        return flags
    }

    private func getSettings(req: Request) async throws -> Settings.Public {
        // get the settings from .json file
        let settings = req.application.directory.workingDirectory
        return try ContentConfiguration()
            .requireDecoder(for: .json)
            .decode(Settings.self,
                    from: try await req.fileio.collectFile(
                        at: settings + "/settings.json"),
                    headers: .init()).asPublic()
    }

}
