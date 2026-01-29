import Foundation
import SwiftData
import SwiftUI

@Model
final class Expense {
    var id: UUID
    var title: String
    var amount: Double
    var date: Date
    var notes: String
    var category: ExpenseCategory?

    init(title: String, amount: Double, date: Date = Date(), notes: String = "", category: ExpenseCategory? = nil) {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.date = date
        self.notes = notes
        self.category = category
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = UserDefaults.standard.string(forKey: "currencyCode") ?? "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

@Model
final class ExpenseCategory {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var budget: Double

    @Relationship(deleteRule: .nullify, inverse: \Expense.category)
    var expenses: [Expense]?

    init(name: String, icon: String, colorHex: String, budget: Double = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.budget = budget
        self.expenses = []
    }

    var color: Color {
        Color(hex: colorHex)
    }

    var totalSpent: Double {
        expenses?.reduce(0) { $0 + $1.amount } ?? 0
    }

    var budgetProgress: Double {
        guard budget > 0 else { return 0 }
        return min(totalSpent / budget, 1.0)
    }
}

// Color extension for hex support
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
            (a, r, g, b) = (255, 0, 0, 0)
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

// Default categories
struct DefaultCategories {
    static let categories: [(name: String, icon: String, colorHex: String)] = [
        ("Food & Dining", "fork.knife", "FF6B6B"),
        ("Transportation", "car.fill", "4ECDC4"),
        ("Shopping", "bag.fill", "45B7D1"),
        ("Entertainment", "tv.fill", "96CEB4"),
        ("Bills & Utilities", "bolt.fill", "FFEAA7"),
        ("Health", "heart.fill", "DDA0DD"),
        ("Travel", "airplane", "98D8C8"),
        ("Education", "book.fill", "F7DC6F"),
        ("Personal Care", "sparkles", "BB8FCE"),
        ("Other", "ellipsis.circle.fill", "95A5A6")
    ]
}

enum TimePeriod: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case thisYear = "This Year"
    case all = "All Time"

    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            return calendar.startOfDay(for: now)
        case .thisWeek:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        case .thisMonth:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        case .thisYear:
            return calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
        case .all:
            return Date.distantPast
        }
    }
}
