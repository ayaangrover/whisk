import SwiftUI
import SwiftData

@main
struct WhiskApp: App {
    @State private var isSignedIn = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Recipe.self,
            GroceryItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if isSignedIn {
                ContentView(isSignedIn: $isSignedIn)
            } else {
                LoginView(isSignedIn: $isSignedIn)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
