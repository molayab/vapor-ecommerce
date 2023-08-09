import Vapor

struct Wompi: PaymentGateway {
    struct WebCheckout {
        var publicKey: String
        var currency: Currency
        var amountInCents: Int
        var reference: String
        var signature: String
        var redirectUrl: String
    }
    
    let fee: Double = 0.0265
    let fixedFee: Double = 700
    
    func checkForStatus() async throws -> Result<GatewayResponse, GatewayError> {
        return .success(.paid)
    }
    
    func pay(transaction: Transaction.Public, req: Request) async throws -> Response {
        let checkout = WebCheckout(
            publicKey: "",
            currency: .COP,
            amountInCents: Int(transaction.total),
            reference: transaction.id,
            signature: "",
            redirectUrl: getRedirectionUrl(txid: transaction.id))
        
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
            URLQueryItem(name: "signature", value: checkout.signature)
        ])
        
        return req.redirect(to: wompiRequest.absoluteString)
    }
    
    private func getRedirectionUrl(txid: String) -> String {
        kSiteDomain + "/payments/wompi/\(txid)"
    }
}
