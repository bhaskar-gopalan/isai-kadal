import Foundation
import CoreData
import Combine

class ExpenseViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    private let dataController = DataController.shared

    @Published var expenses: [Expense] = []
    @Published var categories: [Category] = []
    @Published var selectedPeriod: TimePeriod = .thisMonth
    @Published var searchText: String = ""

    var filteredExpenses: [Expense] {
        if searchText.isEmpty {
            return expenses
        }
        return expenses.filter { expense in
            expense.wrappedTitle.localizedCaseInsensitiveContains(searchText) ||
            expense.category?.wrappedName.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    var totalExpenses: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var formattedTotalExpenses: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: totalExpenses)) ?? "$0.00"
    }

    var expensesByCategory: [(category: Category, total: Double, percentage: Double)] {
        var categoryTotals: [Category: Double] = [:]
        let total = totalExpenses

        for expense in filteredExpenses {
            if let category = expense.category {
                categoryTotals[category, default: 0] += expense.amount
            }
        }

        return categoryTotals.map { category, amount in
            let percentage = total > 0 ? (amount / total) * 100 : 0
            return (category, amount, percentage)
        }.sorted { $0.total > $1.total }
    }

    var expensesByDate: [Date: [Expense]] {
        Dictionary(grouping: filteredExpenses) { expense in
            Calendar.current.startOfDay(for: expense.wrappedDate)
        }
    }

    var sortedDates: [Date] {
        expensesByDate.keys.sorted(by: >)
    }

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchData()
    }

    func fetchData() {
        expenses = dataController.fetchExpenses(for: selectedPeriod)
        categories = dataController.fetchCategories()
    }

    func addExpense(title: String, amount: Double, date: Date, notes: String?, category: Category?) {
        _ = dataController.createExpense(title: title, amount: amount, date: date, notes: notes, category: category)
        fetchData()
    }

    func updateExpense(_ expense: Expense, title: String, amount: Double, date: Date, notes: String?, category: Category?) {
        dataController.updateExpense(expense, title: title, amount: amount, date: date, notes: notes, category: category)
        fetchData()
    }

    func deleteExpense(_ expense: Expense) {
        dataController.deleteExpense(expense)
        fetchData()
    }

    func deleteExpenses(at offsets: IndexSet, from expenses: [Expense]) {
        for index in offsets {
            deleteExpense(expenses[index])
        }
    }

    func addCategory(name: String, icon: String, colorHex: String, budget: Double) {
        _ = dataController.createCategory(name: name, icon: icon, colorHex: colorHex, budget: budget)
        fetchData()
    }

    func updateCategory(_ category: Category, name: String, icon: String, colorHex: String, budget: Double) {
        dataController.updateCategory(category, name: name, icon: icon, colorHex: colorHex, budget: budget)
        fetchData()
    }

    func deleteCategory(_ category: Category) {
        dataController.deleteCategory(category)
        fetchData()
    }

    func changePeriod(to period: TimePeriod) {
        selectedPeriod = period
        fetchData()
    }

    func getDailyExpenses(for days: Int = 7) -> [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dailyTotals: [(date: Date, total: Double)] = []

        for dayOffset in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dayExpenses = expenses.filter { calendar.isDate($0.wrappedDate, inSameDayAs: date) }
            let total = dayExpenses.reduce(0) { $0 + $1.amount }
            dailyTotals.append((date, total))
        }

        return dailyTotals
    }

    func getMonthlyExpenses(for months: Int = 6) -> [(month: String, total: Double)] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"

        var monthlyTotals: [(month: String, total: Double)] = []

        for monthOffset in (0..<months).reversed() {
            guard let date = calendar.date(byAdding: .month, value: -monthOffset, to: Date()) else { continue }
            let components = calendar.dateComponents([.year, .month], from: date)

            let monthExpenses = expenses.filter {
                let expenseComponents = calendar.dateComponents([.year, .month], from: $0.wrappedDate)
                return expenseComponents.year == components.year && expenseComponents.month == components.month
            }

            let total = monthExpenses.reduce(0) { $0 + $1.amount }
            let monthName = dateFormatter.string(from: date)
            monthlyTotals.append((monthName, total))
        }

        return monthlyTotals
    }
}
