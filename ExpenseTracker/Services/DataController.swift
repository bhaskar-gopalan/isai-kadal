import Foundation
import CoreData

class DataController: ObservableObject {
    static let shared = DataController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ExpenseModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        setupDefaultCategories()
    }

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func setupDefaultCategories() {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()

        do {
            let count = try context.count(for: fetchRequest)
            if count == 0 {
                for categoryData in DefaultCategories.categories {
                    let category = Category(context: context)
                    category.id = UUID()
                    category.name = categoryData.name
                    category.icon = categoryData.icon
                    category.colorHex = categoryData.colorHex
                    category.budget = 0
                }
                save()
            }
        } catch {
            print("Error checking categories: \(error)")
        }
    }

    func createExpense(title: String, amount: Double, date: Date, notes: String?, category: Category?) -> Expense {
        let context = container.viewContext
        let expense = Expense(context: context)
        expense.id = UUID()
        expense.title = title
        expense.amount = amount
        expense.date = date
        expense.notes = notes
        expense.category = category
        save()
        return expense
    }

    func updateExpense(_ expense: Expense, title: String, amount: Double, date: Date, notes: String?, category: Category?) {
        expense.title = title
        expense.amount = amount
        expense.date = date
        expense.notes = notes
        expense.category = category
        save()
    }

    func deleteExpense(_ expense: Expense) {
        let context = container.viewContext
        context.delete(expense)
        save()
    }

    func createCategory(name: String, icon: String, colorHex: String, budget: Double) -> Category {
        let context = container.viewContext
        let category = Category(context: context)
        category.id = UUID()
        category.name = name
        category.icon = icon
        category.colorHex = colorHex
        category.budget = budget
        save()
        return category
    }

    func updateCategory(_ category: Category, name: String, icon: String, colorHex: String, budget: Double) {
        category.name = name
        category.icon = icon
        category.colorHex = colorHex
        category.budget = budget
        save()
    }

    func deleteCategory(_ category: Category) {
        let context = container.viewContext
        context.delete(category)
        save()
    }

    func fetchExpenses(for period: TimePeriod = .all) -> [Expense] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Expense> = Expense.sortedFetchRequest()

        if period != .all {
            let calendar = Calendar.current
            let now = Date()
            var startDate: Date

            switch period {
            case .today:
                startDate = calendar.startOfDay(for: now)
            case .thisWeek:
                startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            case .thisMonth:
                startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            case .thisYear:
                startDate = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
            case .all:
                startDate = Date.distantPast
            }

            fetchRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        }

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching expenses: \(error)")
            return []
        }
    }

    func fetchCategories() -> [Category] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Category> = Category.sortedFetchRequest()

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }

    func totalExpenses(for period: TimePeriod = .all) -> Double {
        fetchExpenses(for: period).reduce(0) { $0 + $1.amount }
    }

    func expensesByCategory(for period: TimePeriod = .all) -> [(category: Category, total: Double)] {
        let expenses = fetchExpenses(for: period)
        var categoryTotals: [Category: Double] = [:]

        for expense in expenses {
            if let category = expense.category {
                categoryTotals[category, default: 0] += expense.amount
            }
        }

        return categoryTotals.map { ($0.key, $0.value) }.sorted { $0.total > $1.total }
    }
}

enum TimePeriod: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case thisYear = "This Year"
    case all = "All Time"
}
