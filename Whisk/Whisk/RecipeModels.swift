import SwiftData
import SwiftUI

struct GroqRecipeOutput: Codable {
    var recipeName: String
    var description: String?
    var ingredients: [GroqIngredientOutput]
    var steps: [String]

    struct GroqIngredientOutput: Codable {
        var name: String
        var quantity: String?
    }

    func toRecipe(imageData: Data? = nil) -> Recipe {
        let appIngredients = self.ingredients.map { groqIngredient in
            RecipeIngredient(name: groqIngredient.name, quantity: groqIngredient.quantity ?? "1 serving")
        }
        return Recipe(
            name: self.recipeName,
            recipeDescription: self.description,
            ingredients: appIngredients,
            steps: self.steps,
            imageData: imageData
        )
    }
}

struct RecipeIngredient: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String = ""
    var quantity: String = ""
}

@Model
final class Recipe {
    var id: UUID?
    var name: String?
    var recipeDescription: String?
    var ingredients: [RecipeIngredient]?
    var steps: [String]?
    @Attribute(.externalStorage) var imageData: Data?
    var createdAt: Date?

    init(id: UUID = UUID(),
         name: String = "",
         recipeDescription: String? = nil,
         ingredients: [RecipeIngredient] = [],
         steps: [String] = [],
         imageData: Data? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.recipeDescription = recipeDescription
        self.ingredients = ingredients
        self.steps = steps
        self.imageData = imageData
        self.createdAt = createdAt
    }
}
