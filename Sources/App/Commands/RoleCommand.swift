import Vapor
import Fluent

struct RoleCommand: Command {
    struct Signature: CommandSignature {
        @Argument(name: "subcommand")
        var subcommand: String

        @Option(name: "email", short: "e")
        var email: String?
    }

    var help: String {
"""
Handles the roles in the application.
USAGE: roles <subcommand> [--email <email>]

SUBCOMMANDS:
    list: Lists all roles.

OPTIONS:
    --email <email>: Filters the roles by user email.
"""
    }

    func run(using context: CommandContext, signature: Signature) throws {
        switch signature.subcommand {
        case "list":
            try list(using: context, signature: signature)        default:
            context.console.error("Unknown subcommand '\(signature.subcommand)'. Use 'help' to list available commands.")
        }
    }

    private func list(using context: CommandContext, signature: Signature) throws {
        if let email = signature.email {
            try list(using: context, email: email)
        } else {
            try list(using: context)
        }
    }

    private func list(using context: CommandContext) throws {
        let roles = try Role.query(on: context.application.db)
            .all().wait()
        for role in roles {
            context.console.info("\(role.$user.id) - \(role.$role.wrappedValue)")
        }
    }

    private func list(using context: CommandContext, email: String) throws {
        let roles = try Role.query(on: context.application.db)
            .join(User.self, on: \Role.$user.$id == \User.$id)
            .filter(User.self, \.$email == email)
            .all()
            .wait()

        for role in roles {
            context.console.info("\(role.$user.id) - \(role.$role.wrappedValue)")
        }
    }
}

