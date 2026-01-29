import Foundation
import CoreData
import SwiftUI

@objc(Category)
public class Category: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var icon: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var budget: Double
    @NSManaged public var expenses: NSSet?

    public var wrappedId: UUID {
        id ?? UUID()
    }

    public var wrappedName: String {
        name ?? "Unknown Category"
    }

    public var wrappedIcon: String {
        icon ?? "folder"
    }

    public var wrappedColorHex: String {
        colorHex ?? "#007AFF"
    }

    public var color: Color {
        Color(hex: wrappedColorHex)
    }

    public var expensesArray: [Expense] {
        let set = expenses as? Set<Expense> ?? []
        return set.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
    }

    public var totalExpenses: Double {
        expensesArray.reduce(0) { $0 + $1.amount }
    }

    public var formattedBudget: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: budget)) ?? "$0.00"
    }

    public var formattedTotalExpenses: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: totalExpenses)) ?? "$0.00"
    }

    public var budgetProgress: Double {
        guard budget > 0 else { return 0 }
        return min(totalExpenses / budget, 1.0)
    }

    public var isOverBudget: Bool {
        budget > 0 && totalExpenses > budget
    }
}

extension Category {
    static func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    static func sortedFetchRequest() -> NSFetchRequest<Category> {
        let request = NSFetchRequest<Category>(entityName: "Category")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        return request
    }

    @objc(addExpensesObject:)
    @NSManaged public func addToExpenses(_ value: Expense)

    @objc(removeExpensesObject:)
    @NSManaged public func removeFromExpenses(_ value: Expense)

    @objc(addExpenses:)
    @NSManaged public func addToExpenses(_ values: NSSet)

    @objc(removeExpenses:)
    @NSManaged public func removeFromExpenses(_ values: NSSet)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct DefaultCategories {
    static let categories: [(name: String, icon: String, colorHex: String)] = [
        ("Food & Dining", "fork.knife", "#FF6B6B"),
        ("Transportation", "car.fill", "#4ECDC4"),
        ("Shopping", "bag.fill", "#45B7D1"),
        ("Entertainment", "tv.fill", "#96CEB4"),
        ("Bills & Utilities", "bolt.fill", "#FFEAA7"),
        ("Healthcare", "heart.fill", "#DDA0DD"),
        ("Travel", "airplane", "#98D8C8"),
        ("Education", "book.fill", "#F7DC6F"),
        ("Personal Care", "person.fill", "#BB8FCE"),
        ("Other", "ellipsis.circle.fill", "#85C1E9")
    ]
}
