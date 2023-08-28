import Foundation

#if os(Linux)

extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL? {
        var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = queryItems
        return urlComponents.url
    }
}

#endif
