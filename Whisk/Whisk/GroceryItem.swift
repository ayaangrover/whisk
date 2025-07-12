import Foundation
import SwiftData

@Model
final class GroceryItem {
    var id: UUID? 
    var name: String?
    var quantity: String?
    var isChecked: Bool?
    var createdAt: Date?

    init(id: UUID = UUID(),
         name: String = "",
         quantity: String = "",
         isChecked: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.isChecked = isChecked
        self.createdAt = createdAt
    }
}
