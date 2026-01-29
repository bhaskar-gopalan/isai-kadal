import Foundation
import CoreData

@objc(Expense)
public class Expense: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var amount: Double
    @NSManaged public var date: Date?
    @NSManaged public var notes: String?
    @NSManaged public var receiptImageData: Data?
    @NSManaged public var category: Category?

    public var wrappedId: UUID {
        id ?? UUID()
    }

    public var wrappedTitle: String {
        title ?? "Unknown Expense"
    }

    public var wrappedDate: Date {
        date ?? Date()
    }

    public var wrappedNotes: String {
        notes ?? ""
    }

    public var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: wrappedDate)
    }
}

extension Expense {
    static func fetchRequest() -> NSFetchRequest<Expense> {
        return NSFetchRequest<Expense>(entityName: "Expense")
    }

    static func sortedFetchRequest() -> NSFetchRequest<Expense> {
        let request = NSFetchRequest<Expense>(entityName: "Expense")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Expense.date, ascending: false)]
        return request
    }

    static func fetchRequestForCategory(_ category: Category) -> NSFetchRequest<Expense> {
        let request = NSFetchRequest<Expense>(entityName: "Expense")
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Expense.date, ascending: false)]
        return request
    }

    static func fetchRequestForDateRange(from startDate: Date, to endDate: Date) -> NSFetchRequest<Expense> {
        let request = NSFetchRequest<Expense>(entityName: "Expense")
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Expense.date, ascending: false)]
        return request
    }
}
