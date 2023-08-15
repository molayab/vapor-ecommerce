import Vapor
import Fluent
import Fakery

struct ProductCommand: Command {
    struct Signature: CommandSignature {
        @Argument(name: "subcommand")
        var subcommand: String
    }
    
    var help: String {
        ""
    }
    
    func run(using context: CommandContext, signature: Signature) throws {
        switch signature.subcommand {
        case "create":
            try create(using: context, signature: signature)
        case "list":
            try list(using: context, signature: signature)
        case "delete":
            try delete(using: context, signature: signature)
        case "randomize": break
            // try randomize(using: context, signature: signature)
        default:
            context.console.error("Invalid subcommand: \(signature.subcommand)")
        
        }
    }
    
    private func delete(using context: CommandContext, signature: Signature) throws {
        let id = context.console.ask("Product ID?")
        guard let uuid = UUID(uuidString: id) else {
            context.console.error("Invalid UUID: \(id)")
            return
        }
        
        guard let product = try Product.find(uuid, on: context.application.db).wait() else {
            context.console.error("No product found with ID: \(id)")
            return
        }
        
        let variants = try product.$variants.get(on: context.application.db).wait()

        try variants.delete(on: context.application.db).wait()
        try product.delete(on: context.application.db).wait()
        context.console.info("Product deleted")
    }
    
    private func list(using context: CommandContext, signature: Signature) throws {
        let products = try Product.query(on: context.application.db).all().wait()
        for product in products {
            context.console.info("\(product.id ?? UUID()) - \(product.title)")
            
            for variant in try product.$variants.get(on: context.application.db).wait() {
                context.console.info("  - \(variant.name) - \(variant.price)")
            }
        }
    }
    
    
    
    private func create(using context: CommandContext, signature: Signature) throws {
        while true {
            var categoryId: UUID?
            
            let title = context.console.ask("Product title?")
            let description = context.console.ask("Product description?")
            let category = context.console.ask("Product category?")
            let model = Product()
            model.id = UUID()
            model.title = title
            model.description = description
            
            // Find category
            let categories = try Category.query(on: context.application.db)
                .filter(\.$title == category).all().wait()
            
            if categories.isEmpty {
                context.console.error("No category found with title: \(category)")
                context.console.info("Creating category: \(category)")
                
                let category = Category(model: Category.Create(title: category))
                try category.save(on: context.application.db).wait()
                
                categoryId = try category.requireID()
            } else {
                categoryId = try categories.first?.requireID()
            }
            
            var variants = [ProductVariant]()
            while true {
                let name = context.console.ask("Variant name?")
                let salePrice = Double(context.console.ask("Variant sale price?")) ?? 0.0
                let price = Double(context.console.ask("Variant price?")) ?? 0.0
                let isAvailable = context.console.confirm("Variant available?")
                
                let variant = ProductVariant()
                variant.name = name
                variant.salePrice = salePrice
                variant.price = price
                variant.isAvailable = isAvailable
                variant.$product.id = try model.requireID()
                
                variants.append(variant)
                if !context.console.confirm("Add another variant?") {
                    break
                }
            }
            
            model.$category.id = categoryId ?? UUID()
            try model.save(on: context.application.db).wait()
            
            context.console.info("Product created: \(model.title)")
            try variants.create(on: context.application.db).wait()
            
            if !context.console.confirm("Create another product?") {
                break
            }
        }
    }
    
}
