import Vapor
import Fluent

/// The controller for the checkout endpoints.
struct CheckoutController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        // Public API
        let transactions = routes.grouped("orders")
        transactions.post("checkout", use: checkout)

        // Internal API
        let requiredAuth = transactions.grouped(
            UserSessionAuthenticator(),
            User.guardMiddleware())
        let pos = requiredAuth.grouped(RoleMiddleware(roles: [.admin, .manager, .pos]))
        pos.post("checkout", ":method", use: checkoutPos)

        // Restricted API
        let restricted = requiredAuth.grouped(RoleMiddleware(roles: [.admin, .manager]))
        restricted.delete("anulate", use: anulate)
    }

    /// Public API
    /// POST /transactions/checkout
    /// This endpoint is used to create a new transaction.
    private func checkout(req: Request) async throws -> Transaction.Public {
        let payload = try req.content.get(Transaction.Create.self)
        return try await payload.create(in: req, forOrigin: .web).asPublic(on: req.db)
    }

    /// Retricted API
    /// POST /transactions/checkout/pos/:method
    /// This endpoint is used to create a new transaction.
    private func checkoutPos(req: Request) async throws -> Transaction.Public {
        try await req.ensureFeatureEnabled(.posEnabled)

        guard let methodParameter = req.parameters.get("method", as: String.self) else {
            throw Abort(.badRequest)
        }
        guard let method = Transaction.Origin(rawValue: methodParameter) else {
            throw Abort(.badRequest)
        }

        let payload = try req.content.get(Transaction.Create.self)
        let transaction = try await payload.create(in: req, forOrigin: method)

        // Transaction is payed, and created by a POS, so we can mark it as payed, add it to\
        // the sales records and send an email confirmation.

        // Send email confirmation
        if let billTo = payload.billTo, req.application.environment == .production {
            // lets use the api call 
            // todo create a custom provider
            var headers = HTTPHeaders()
            headers.add(name: .accept, value: "application/json")
            headers.add(name: .contentType, value: "application/json")
            headers.add(name: "api-key", value: settings.secrets.smtp.password)

            let response = try await req.client.post(
                    URI(string: settings.secrets.smtp.hostname), 
                    headers: headers, 
                    content: EmailSender(
                        sender: EmailSender.User(
                            name: settings.siteName,
                            email: settings.secrets.smtp.email
                        ),
                        to: [
                            EmailSender.User(
                                name: billTo.name.capitalized,
                                email: billTo.email)
                        ],
                        subject: "Confirmación de Compra",
                        htmlContent: try await transaction.generateEmailConfirmation(database: req.db)))

            req.logger.info("\(response)")
        }

        await req.notifyMessage("La transacción \(transaction.id!.uuidString) ha sido creada.")
        return try await transaction.asPublic(on: req.db)
    }

    /// Restricted API
    /// DELETE /transactions/anulate
    /// This endpoint is used to anulate a transaction. It will restore the stock of the 
    /// products and remove the sales.
    private func anulate(req: Request) async throws -> Response {
        let payload = try req.content.get(Transaction.Anulate.self)
        _ = try await payload.anulate(in: req)

        await req.notifyMessage("La transacción \(payload.id.uuidString) ha sido anulada.")
        return Response(status: .ok)
    }
}

struct EmailSender: Content {
    struct User: Content {
        let name: String
        let email: String
    }

    let sender: User
    let to: [User]
    let subject: String
    let htmlContent: String
}