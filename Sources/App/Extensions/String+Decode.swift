import Foundation

extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self.replacingOccurrences(of: "_", with: "="), options: Data.Base64DecodingOptions(rawValue: 0)) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}
