import Vapor
import Fluent
import Fakery

struct UserCommand: Command {
    struct Signature: CommandSignature {
        @Argument(name: "subcommand")
        var subcommand: String

        @Option(name: "name", short: "n")
        var name: String?

        @Option(name: "email", short: "e")
        var email: String?

        @Option(name: "password", short: "p")
        var password: String?

        @Option(name: "kind", short: "k")
        var kind: String?

        @Option(name: "roles", short: "r")
        var roles: String?

        @Option(name: "entries", short: "c")
        var entries: Int?

        @Flag(name: "active", short: "a")
        var isActive: Bool
    }

    var help: String {
        "Seeds the database with some test data."
    }

    func run(using context: CommandContext, signature: Signature) throws {
        switch signature.subcommand {
        case "create":
            try create(using: context, signature: signature)
        case "randomize":
            try randomize(using: context, signature: signature)
        default:
            context.console.error("Invalid subcommand: \(signature.subcommand)")
        }

        
    }

    private func randomize(using context: CommandContext, signature: Signature) throws {
        guard let entries = signature.entries else {
            context.console.error("Missing required argument: entries")
            return 
        }

        guard let password = signature.password else {
            context.console.error("Missing required argument: password")
            return 
        }

        let asyncProcesses = 1024
        let app = context.application
        let roles = signature
            .roles?
            .split(separator: ",")
            .map { AvailableRoles(rawValue: String($0))! } ?? [.noAccess]
        let kind = signature.kind.flatMap(UserKind.init(rawValue:)) ?? .employee
        let promise = context.application.eventLoopGroup.makeFutureWithTask {
          let faker = Faker()
          let password = try! Bcrypt.hash(password)
          let loopTo = entries / asyncProcesses
          
          await withTaskGroup(of: Void.self) { group in
            (0..<asyncProcesses).forEach { index in
              group.addTask(priority: .high) {
                context.console.info("Spawning task \(index)...")

                var roles = [Role]()
                let requests = (0..<loopTo).compactMap { _ in 
                  let user = try! User(create: User.Create(
                    name: faker.name.name(),
                    kind: kind,
                    password: password,
                    email: faker.internet.email(),
                    roles: [],
                    isActive: signature.isActive
                  ), isHashed: true)

                  user.id = UUID()
                  roles.append(Role(
                    role: .noAccess, 
                    userId: try! user.requireID()))
                  
                  return user
                }

                do {
                  context.console.info("Creating users for task \(index)...")
                  try await requests.create(on: app.db)
                  try await roles.create(on: app.db)
                  context.console.info("Users created. \(requests.count))")
                } catch {
                  context.console.error("User already exists.")
                }
              }
            }
          }

          // Add the remaining entries
          let remaining = entries % asyncProcesses
          var roles = [Role]()
          let requests = (0..<remaining).compactMap { _ in 
            let user = try! User(create: User.Create(
              name: faker.name.name(),
              kind: kind,
              password: password,
              email: faker.internet.email(),
              roles: [],
              isActive: signature.isActive
            ), isHashed: true)
            
            user.id = UUID()
            roles.append(Role(
              role: .noAccess, 
              userId: try! user.requireID()))

              return user
          }

          try await requests.create(on: app.db)
          try await roles.create(on: app.db)
          context.console.info("Random users created.")
        }

        try promise.wait()
    }

    private func create(using context: CommandContext, signature: Signature) throws {
        guard let email = signature.email else {
            context.console.error("Missing required argument: name")
            return 
        }

        guard let password = signature.password else {
            context.console.error("Missing required argument: password")
            return 
        }

        let app = context.application
        let roles = signature
            .roles?
            .split(separator: ",")
            .map { AvailableRoles(rawValue: String($0))! } ?? [.noAccess]
        let kind = signature.kind.flatMap(UserKind.init(rawValue:)) ?? .employee

        let promise = context.application.eventLoopGroup.makeFutureWithTask {
            // Create root user if not exists
            if try await app.db.query(User.self).filter(\.$email == email).first() == nil {
                let rootUser = User.Create(
                    name: signature.name ?? "No Name",
                    kind: kind,
                    password: password,
                    email: email,
                    roles: roles,
                    isActive: signature.isActive
                )

                try await rootUser.create(on: app.db, option: .natural)
                context.console.info("Root user created.")
            } else {
                context.console.info("Root user already exists.")
            }
        }

        try promise.wait()
    }
}