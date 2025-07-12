import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.dismiss) var dismiss
    let recipe: Recipe
    var onEdit: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section {
                    if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .cornerRadius(12)
                            .listRowInsets(EdgeInsets()) 
                    }
                }

                Section(header: Text("Description")) {
                    if let description = recipe.recipeDescription, !description.isEmpty {
                        Text(description)
                    } else {
                        Text("No description provided.")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Ingredients")) {
                    ForEach(recipe.ingredients ?? []) { ingredient in
                        VStack(alignment: .leading) {
                            Text(ingredient.name)
                                .fontWeight(.medium)
                            if !ingredient.quantity.isEmpty {
                                Text(ingredient.quantity)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section(header: Text("Steps")) {
                    ForEach(0..<(recipe.steps?.count ?? 0), id: \.self) { index in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .fontWeight(.bold)
                            Text((recipe.steps ?? [])[index])
                        }
                    }
                }
            }
            .navigationTitle(recipe.name ?? "Untitled Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        onEdit()
                    }
                }
            }
        }
    }
}

struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRecipe = Recipe(
            name: "Preview Pancakes",
            recipeDescription: "Fluffy pancakes",
            ingredients: [
                RecipeIngredient(name: "Flour", quantity: "1 cup"),
                RecipeIngredient(name: "Milk", quantity: "1 cup"),
                RecipeIngredient(name: "Egg", quantity: "2")
            ],
            steps: ["Mix all ingredients together.", "Cook on a hot griddle until golden brown.", "Serve with your favorite toppings."],
            imageData: nil
        )
        
        RecipeDetailView(recipe: sampleRecipe, onEdit: {})
            .modelContainer(for: Recipe.self, inMemory: true)
    }
}
