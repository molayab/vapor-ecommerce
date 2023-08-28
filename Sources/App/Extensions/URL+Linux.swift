import Foundation

#if os(Linux)

extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            return self
        }
        
        urlComponents.queryItems = queryItems
        return urlComponents.url ?? self
    }
}

#endif
