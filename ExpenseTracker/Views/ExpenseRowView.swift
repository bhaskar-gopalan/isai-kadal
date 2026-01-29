import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(expense.category?.color ?? Color.gray)
                    .frame(width: 44, height: 44)

                Image(systemName: expense.category?.wrappedIcon ?? "questionmark")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }

            // Expense Info
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.wrappedTitle)
                    .font(.headline)
                    .lineLimit(1)

                Text(expense.category?.wrappedName ?? "Uncategorized")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(expense.formattedAmount)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(expense.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let context = DataController.shared.container.viewContext
    let expense = Expense(context: context)
    expense.id = UUID()
    expense.title = "Coffee"
    expense.amount = 4.50
    expense.date = Date()

    return ExpenseRowView(expense: expense)
        .padding()
        .previewLayout(.sizeThatFits)
}
