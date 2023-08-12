import Vapor
import Fluent

struct CountriesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        // Public API
        let countries = routes.grouped("countries")
        
        countries.get(use: getAllCountries)
    }
    
    private func getAllCountries(req: Request) async throws -> [CountryContent] {
        return Country.allCases.map { $0.asPublic() }
    }
}
