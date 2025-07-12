import SwiftUI
import SwiftData
import PhotosUI

struct AddEditRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    var recipeToEdit: Recipe?

    @State private var recipeName: String = ""
    @State private var recipeDescription: String = ""
    @State private var ingredients: [RecipeIngredient] = []
    @State private var steps: [String] = [""] 
    @State private var selectedImageData: Data? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showingImagePicker = false 

    var isEditing: Bool {
        recipeToEdit != nil
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recipe Details")) {
                    TextField("Recipe Name", text: $recipeName)
                    TextField("Description (Optional)", text: $recipeDescription, axis: .vertical)
                        .lineLimit(3...)
                }

                Section(header: Text("Photo")) {
                    if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if let recipeToEditImageData = recipeToEdit?.imageData, let uiImage = UIImage(data: recipeToEditImageData) {
                         Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Image(systemName: "photo.badge.plus")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                        Text(selectedImageData != nil || (isEditing && recipeToEdit?.imageData != nil) ? "Change Image" : "Add Image")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .onChange(of: selectedPhoto) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }
                    if selectedImageData != nil || (isEditing && recipeToEdit?.imageData != nil) {
                        Button("Remove Image", role: .destructive) {
                            selectedImageData = nil
                            selectedPhoto = nil
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                Section(header: Text("Ingredients")) {
                    ForEach($ingredients) { $ingredient in
                        HStack {
                            TextField("Ingredient Name", text: $ingredient.name)
                            Divider()
                            TextField("Quantity", text: $ingredient.quantity)
                        }
                    }
                    .onDelete(perform: deleteIngredient)

                    Button("Add Ingredient") {
                        ingredients.append(RecipeIngredient(name: "", quantity: ""))
                    }
                    .buttonStyle(SubtleButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Section(header: Text("Steps")) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                            TextField("Step description", text: $steps[index], axis: .vertical)
                                .lineLimit(2...)
                        }
                    }
                    .onDelete(perform: deleteStep)

                    Button("Add Step") {
                        steps.append("")
                    }
                    .buttonStyle(SubtleButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle(isEditing ? "Edit Recipe" : "Add Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRecipe()
                        dismiss()
                    }
                    .disabled(recipeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let recipe = recipeToEdit {
                    recipeName = recipe.name ?? ""
                    recipeDescription = recipe.recipeDescription ?? ""
                    ingredients = (recipe.ingredients ?? []).map { RecipeIngredient(id: $0.id, name: $0.name, quantity: $0.quantity) }
                    steps = recipe.steps ?? []
                    selectedImageData = recipe.imageData 
                } else {
                    if ingredients.isEmpty {
                        ingredients.append(RecipeIngredient(name: "", quantity: ""))
                    }
                    if steps.isEmpty || (steps.count == 1 && steps[0].isEmpty) {
                        steps = [""]
                    }
                }
            }
        }
    }

    private func deleteIngredient(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
        if ingredients.isEmpty { 
            ingredients.append(RecipeIngredient(name: "", quantity: ""))
        }
    }

    private func deleteStep(at offsets: IndexSet) {
        steps.remove(atOffsets: offsets)
        if steps.isEmpty { 
            steps.append("")
        }
    }

    private func saveRecipe() {
        let finalIngredients = ingredients.filter {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !$0.quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let finalSteps = steps.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        if let recipe = recipeToEdit { 
            recipe.name = recipeName.trimmingCharacters(in: .whitespacesAndNewlines)
            recipe.recipeDescription = recipeDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : recipeDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            recipe.ingredients = finalIngredients
            recipe.steps = finalSteps
            recipe.imageData = selectedImageData 
        } else { 
            let newRecipe = Recipe(
                name: recipeName.trimmingCharacters(in: .whitespacesAndNewlines),
                recipeDescription: recipeDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : recipeDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                ingredients: finalIngredients,
                steps: finalSteps,
                imageData: selectedImageData,
                createdAt: Date() 
            )
            modelContext.insert(newRecipe)
        }
    }
}