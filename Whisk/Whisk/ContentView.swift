import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Recipe.createdAt, order: .reverse)]) private var recipes: [Recipe]
    @Binding var isSignedIn: Bool

    @State private var showingAddRecipeSheet = false
    @State private var showingOCRSheet = false
    @State private var recipeToEdit: Recipe? = nil
    @State private var showingRecipeDetailSheet = false
    @State private var selectedRecipeForDetail: Recipe? = nil
    @State private var showingGroceryListSheet = false
    @State private var showingSettingsSheet = false

    enum DisplayMode { case list, grid }
    @State private var displayMode: DisplayMode = .list

    @State private var searchText: String = ""
    
    @State private var isLoadingOcrText: Bool = false
    @State private var ocrError: String? = nil 

    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipes
        } else {
            let lowercasedSearchText = searchText.lowercased()
            return recipes.filter {
                ($0.name ?? "").lowercased().contains(lowercasedSearchText) ||
                ($0.recipeDescription ?? "").lowercased().contains(lowercasedSearchText) ||
                ($0.ingredients ?? []).contains(where: { $0.name.lowercased().contains(lowercasedSearchText) }) ||
                ($0.steps ?? []).contains(where: { $0.lowercased().contains(lowercasedSearchText) })
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if isLoadingOcrText {
                    ProgressView("Processing scanned recipe...")
                        .padding()
                }
                if let ocrError = ocrError {
                    Text("Error: \(ocrError)")
                        .foregroundColor(.red)
                        .padding()
                        .onTapGesture { self.ocrError = nil }
                }
                
                if recipes.isEmpty && !isLoadingOcrText {
                    ContentUnavailableView {
                        Label("No Recipes Yet", systemImage: "fork.knife.circle")
                    } description: {
                        Text("Tap the '+' button to add your first recipe or scan one.")
                    }
                } else {
                    if displayMode == .list {
                        List {
                            ForEach(filteredRecipes) { recipe in
                                RecipeRow(recipe: recipe)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedRecipeForDetail = recipe
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            deleteRecipe(recipe)
                                        } label: {
                                            Label("Delete", systemImage: "trash.fill")
                                        }
                                        Button {
                                            recipeToEdit = recipe
                                            showingAddRecipeSheet = true
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                            }
                        }
                    } else { 
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                                ForEach(filteredRecipes) { recipe in
                                    RecipeGridItemView(recipe: recipe)
                                        .onTapGesture {
                                            selectedRecipeForDetail = recipe
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("My Recipes")
            .searchable(text: $searchText, prompt: "Search recipes, ingredients...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button {
                            showingSettingsSheet = true
                        } label: {
                            Image(systemName: "gear")
                        }
                        Picker("View Mode", selection: $displayMode) {
                            Label("List", systemImage: "list.bullet").tag(DisplayMode.list)
                            Label("Grid", systemImage: "square.grid.2x2").tag(DisplayMode.grid)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            recipeToEdit = nil 
                            selectedRecipeForDetail = nil 
                            showingAddRecipeSheet = true
                        } label: {
                            Label("Add Recipe", systemImage: "square.and.pencil")
                        }
                        
                        Button {
                            ocrError = nil 
                            showingOCRSheet = true
                        } label: {
                            Label("Scan Recipe (OCR)", systemImage: "doc.text.viewfinder")
                        }
                        
                        Button {
                            showingGroceryListSheet = true
                        } label: {
                            Label("Edit Grocery List", systemImage: "list.bullet.clipboard")
                        }
                        
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .sheet(isPresented: $showingAddRecipeSheet, onDismiss: { recipeToEdit = nil }) {
                AddEditRecipeView(recipeToEdit: recipeToEdit)
            }
            .sheet(item: $selectedRecipeForDetail) { recipe in 
                 RecipeDetailView(recipe: recipe, onEdit: {
                     recipeToEdit = recipe 
                     selectedRecipeForDetail = nil 
                     showingAddRecipeSheet = true 
                 })
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView(isSignedIn: $isSignedIn)
            }
            .sheet(isPresented: $showingOCRSheet) {
                OCRScannerView { recognizedText in
                    isLoadingOcrText = true
                    ocrError = nil
                    let groqService = GroqService()
                    groqService.fetchRecipeFromGroq(ocrText: recognizedText) { result in
                        DispatchQueue.main.async {
                            isLoadingOcrText = false
                            switch result {
                            case .success(let groqRecipeOutput):
                                let newRecipe = groqRecipeOutput.toRecipe()
                                modelContext.insert(newRecipe)
                                showingOCRSheet = false
                            case .failure(let error):
                                print("Error processing scanned recipe with Groq: \(error.localizedDescription)")
                                self.ocrError = error.localizedDescription
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingGroceryListSheet) { 
                GroceryListView()
            }
        }
    }

    private func deleteRecipe(_ recipe: Recipe) {
        modelContext.delete(recipe)
    }
}

struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        HStack {
            if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    .clipped()
            } else {
                Image(systemName: "photo.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    .foregroundColor(.gray)
                    .background(Color.gray.opacity(0.1))
            }
            VStack(alignment: .leading) {
                Text(recipe.name!)
                    .font(.headline)
                Text(recipe.recipeDescription ?? "No description")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
    }
}

struct RecipeGridItemView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading) {
            if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
                    .overlay(Image(systemName: "photo").foregroundColor(.gray))
                    .cornerRadius(8)
            }
            Text(recipe.name!)
                .font(.headline)
                .lineLimit(2)
            Text(recipe.recipeDescription ?? "")
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .padding(8)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .shadow(radius: 2, x: 0, y: 1)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(isSignedIn: .constant(true))
            .modelContainer(for: Recipe.self, inMemory: true)
    }
}
