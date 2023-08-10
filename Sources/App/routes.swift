import Fluent
import Vapor

func routes(_ app: Application) throws {
    let api = app.grouped("v1")

    app.get { req in
        return "It works! This is the API endpoint. Please refer to the documentation for more information."
    }
    
    try api.register(collection: AuthenticationController())
    try api.register(collection: UsersController())
    try api.register(collection: CategoriesController())
    try api.register(collection: ProductsController())
    try api.register(collection: ProductReviewsController())
    try api.register(collection: ProductVariantsController())
    try api.register(collection: ProductQuestionsController())
    try api.register(collection: OrdersController())
    try api.register(collection: PaymentsController())
}

extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}
