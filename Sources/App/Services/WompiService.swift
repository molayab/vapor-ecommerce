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
        var amount_in_cents: Int
        var reference: String
        var customer_email: String
        var currency: String
        var payment_method_type: String
        var status: String
        
        var dictionary: [String: String] {
            [
                "id": id,
                "amount_in_cents": "\(amount_in_cents)",
                "reference": reference,
                "customer_email": customer_email,
                "currency": currency,
                "payment_method_type": payment_method_type,
                "status": status
            ]
        }
    }
    
    struct WebCheckout {
        var publicKey: String
        var currency: Currency
        var amountInCents: Int
        var reference: String
        var signature: String
        var redirectUrl: String
        var expirationDate: Date
    }
    
    let fee: Double = 0.0265
    let fixedFee: Double = 700
    
    func checkEvent(for req: Request) async throws -> PaymentEvent {
        let payload = try req.content.decode(EventPayload.self)
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
        }
    }
    
    func pay(transaction: Transaction.Public, req: Request) async throws -> Response {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        let expirationDate = Date().addingTimeInterval(60 * 60 * 2)
        let signature = "\(transaction.id)\(transaction.total)COP\(formatter.string(from: expirationDate))\(settings.wompi.configuration.integrityKey)"
        
        let checkout = WebCheckout(
            publicKey: settings.wompi.configuration.publicKey,
            currency: .COP,
            amountInCents: Int(transaction.total),
            reference: transaction.id,
            signature: signature.sha256(),
            redirectUrl: getRedirectionUrl(txid: transaction.id),
            expirationDate: expirationDate)
        
        // Make a post request to wompi using HTML form
        guard let url = URL(string: "https://checkout.wompi.co/p/") else {
            throw Abort(.internalServerError)
        }
        
        let wompiRequest = url.appending(queryItems: [
            URLQueryItem(name: "public-key", value: checkout.publicKey),
            URLQueryItem(name: "currency", value: checkout.currency.rawValue),
            URLQueryItem(name: "amount-in-cents", value: String(checkout.amountInCents)),
            URLQueryItem(name: "reference", value: checkout.reference),
            URLQueryItem(name: "redirect-url", value: checkout.redirectUrl),
            URLQueryItem(name: "signature%3Aintegrity", value: checkout.signature),
            URLQueryItem(name: "expiration-time", value: formatter.string(from: checkout.expirationDate))
        ])
        
        return req.redirect(to: wompiRequest.absoluteString)
    }
    
    private func getRedirectionUrl(txid: String) -> String {
        settings.siteUrl + "/payments/wompi/\(txid)"
    }
}
