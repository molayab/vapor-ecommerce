import Vapor
import Fluent

struct CostsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let costs = routes.grouped("finance", "costs")
        
        // Private API
        let requiredAuth = costs.grouped(
            UserSessionAuthenticator(),
            User.guardMiddleware())
        
        // Restricted API
        let restricted = requiredAuth.grouped(
            RoleMiddleware(roles: [.admin, .manager]))
        
        restricted.post(use: createCost)
        restricted.get("fixed", use: getFixedCosts)
        restricted.get("variable", use: getVariableCosts)
        restricted.get("all", use: getAllCosts)
        restricted.get(use: getAllCostsPaginated)
        restricted.delete(":costId", use: deleteCost)
        restricted.patch(":costId", use: updateCost)
        restricted.get(":costId", use: getCost)
    }
    
    private func createCost(req: Request) async throws -> Cost.Public {
        let payload = try req.content.decode(Cost.Create.self)
        try Cost.Create.validate(content: req)
        
        let cost = payload.createModel()
        try await cost.save(on: req.db)
        return try cost.asPublic()
    }
    
    private func deleteCost(req: Request) async throws -> Response {
        let costId = try req.parameters.require("costId", as: UUID.self)
        guard let cost = try await Cost.find(costId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await cost.delete(on: req.db)
        return Response(status: .ok)
    }
    
    private func updateCost(req: Request) async throws -> Cost.Public {
        let costId = try req.parameters.require("costId", as: UUID.self)
        guard let cost = try await Cost.find(costId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let payload = try req.content.decode(Cost.Update.self)
        try Cost.Update.validate(content: req)
        
        cost.name = payload.name
        cost.amount = payload.amount
        cost.type = payload.type
        cost.startDate = payload.startDate
        cost.periodicity = payload.periodicity
        cost.currency = payload.currency
        
        try await cost.save(on: req.db)
        return try cost.asPublic()
    }
    
    private func getCost(req: Request) async throws -> Cost.Public {
        let costId = try req.parameters.require("costId", as: UUID.self)
        guard let cost = try await Cost.find(costId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        return try cost.asPublic()
    }
    
    private func getFixedCosts(req: Request) async throws -> [Cost.Public] {
        let costs = try await Cost.query(on: req.db)
            .filter(\.$type == .fixed)
            .all()
        return try costs.map { try $0.asPublic() }
    }
    
    private func getVariableCosts(req: Request) async throws -> [Cost.Public] {
        let costs = try await Cost.query(on: req.db)
            .filter(\.$type == .variable)
            .all()
        return try costs.map { try $0.asPublic() }
    }
    
    private func getAllCosts(req: Request) async throws -> [Cost.Public] {
        let costs = try await Cost.query(on: req.db)
            .all()
        return try costs.map { try $0.asPublic() }
    }
    
    private func getAllCostsPaginated(req: Request) async throws -> Page<Cost> {
        return try await Cost.query(on: req.db)
            .paginate(for: req)
    }
}
