import Vapor

struct WompiService: PaymentGatewayProtocol {
    struct EventPayload: Content {
        var event: String
        var data: EventPayloadData
        var environment: String
        var timestamp: Int
        var signature: EventSignature
    }

    struct EventSignature: Content {
        var checksum: String
        var properties: [String]
    }

    struct EventPayloadData: Content {
        var transaction: EventPayloadTransaction
    }

    struct EventPayloadTransaction: Content {
        var id: String
        var amountInCents: Int
        var reference: String
        var customerEmail: String
        var currency: String
        var paymentMethodType: String
        var status: String

        var dictionary: [String: String] {
            [
                "id": id,
                "amount_in_cents": "\(amountInCents)",
                "reference": reference,
                "customer_email": customerEmail,
                "currency": currency,
                "payment_method_type": paymentMethodType,
                "status": status
            ]
        }

        enum CodingKeys: String, CodingKey {
            case id, reference, currency, status
            case amountInCents = "amount_in_cents"
            case customerEmail = "customer_email"
            case paymentMethodType = "payment_method_type"
        }
    }

    struct WebCheckout {
        var publicKey: String
        var currency: Currency
        var amountInCents: Int
        var reference: String
        var signature: String
        var redirectUrl: String
        var expirationDate: String
    }

    let fee: Double = 0.0265
    let fixedFee: Double = 700

    func checkEvent(for req: Request) async throws -> PaymentEvent {
        /*let payload = try req.content.decode(EventPayload.self)
        guard payload.event == "transaction.updated" else {
            throw Abort(.badRequest)
        }

        // Validate signature
        let signature = req.headers.first(name: "X-Event-Checksum")!
        let dict = payload.data.transaction.dictionary
        var calculatedSignature = payload.signature.properties.compactMap {
            guard let key = $0.split(separator: ".").last else { return nil }
            return dict[String(key)]
        }
        .joined(separator: "")

        calculatedSignature.append(String(payload.timestamp))
        calculatedSignature.append(settings.wompi.configuration.privateKey)

        guard let data = calculatedSignature.data(using: .utf8) else {
            throw Abort(.internalServerError)
        }

        let hashedSignature = SHA256.hash(data: data).hex
        guard hashedSignature == signature else {
            throw Abort(.badRequest)
        }

        // Check if the event status
        if payload.data.transaction.status == "APPROVED" {
            return .init(
                reference: payload.data.transaction.reference,
                status: .approved)
        } else if payload.data.transaction.status == "DECLINED"
                    || payload.data.transaction.status == "ERROR" {
            return .init(
                reference: payload.data.transaction.reference,
                status: .declined)
        } else {
            return .init(
                reference: payload.data.transaction.reference,
                status: .inProgress)
        }*/

        return .init(reference: "", status: .approved)

    }

    func pay(transaction: Transaction.Public, req: Request) async throws -> Response {
        /*let expirationDate = "DATE IN ISO"
        let signature = "\(transaction.id)\(transaction.total)COP\(expirationDate)\(settings.wompi.configuration.integrityKey)"

        _ = WebCheckout(
            publicKey: settings.wompi.configuration.publicKey,
            currency: .COP,
            amountInCents: Int(transaction.total),
            reference: transaction.id,
            signature: signature.sha256(),
            redirectUrl: getRedirectionUrl(txid: transaction.id),
            expirationDate: expirationDate)

        /*let wompiRequest = url.appending(queryItems: [
            URLQueryItem(name: "public-key", value: checkout.publicKey),
            URLQueryItem(name: "currency", value: checkout.currency.rawValue),
            URLQueryItem(name: "amount-in-cents", value: String(checkout.amountInCents)),
            URLQueryItem(name: "reference", value: checkout.reference),
            URLQueryItem(name: "redirect-url", value: checkout.redirectUrl),
            URLQueryItem(name: "signature%3Aintegrity", value: checkout.signature),
            URLQueryItem(name: "expiration-time", value: checkout.expirationDate)
        ])*/*/

        return req.redirect(to: "https://checkout.wompi.co/p/")
    }

    private func getRedirectionUrl(txid: String) -> String {
        settings.siteUrl + "/payments/wompi/\(txid)"
    }
}
