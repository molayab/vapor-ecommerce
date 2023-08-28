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
    try api.register(collection: CostsController())
    try api.register(collection: SalesController())
    try api.register(collection: CountriesController())
    try api.register(collection: ProductImagesController())
    try api.register(collection: SettingsController())
    try api.register(collection: CheckoutController())
    try api.register(collection: DashboardController())
}
