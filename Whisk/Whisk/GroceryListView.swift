import SwiftUI
import SwiftData

struct GroceryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query(sort: \GroceryItem.createdAt) private var items: [GroceryItem]

    @State private var newItemName: String = ""
    @State private var newItemQuantity: String = ""

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("New Item Name", text: $newItemName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Quantity (e.g., 2 lbs)", text: $newItemQuantity)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                    Button(action: addItem) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                    .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()

                List {
                    ForEach(items) { item in
                        GroceryListRow(item: item)
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("Grocery List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func addItem() {
        let trimmedName = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedQuantity = newItemQuantity.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            let newItem = GroceryItem(name: trimmedName, quantity: trimmedQuantity, isChecked: false, createdAt: Date())
            modelContext.insert(newItem)
            newItemName = ""
            newItemQuantity = ""
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

struct GroceryListRow: View {
    @Bindable var item: GroceryItem

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name ?? "Untitled Item")
                    .font(.headline)
                    .strikethrough(item.isChecked ?? false, color: .primary)
                if let quantity = item.quantity, !quantity.isEmpty {
                    Text(quantity)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .strikethrough(item.isChecked ?? false, color: .gray)
                }
            }
            Spacer()
            Image(systemName: (item.isChecked ?? false) ? "checkmark.circle.fill" : "circle")
                .foregroundColor((item.isChecked ?? false) ? .green : .gray)
                .font(.title2)
                .onTapGesture {
                    item.isChecked = !(item.isChecked ?? false)
                }
        }
        .opacity((item.isChecked ?? false) ? 0.6 : 1.0)
    }
}
