import SwiftUI

struct ExpenseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ExpenseViewModel

    let expense: Expense
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Amount Card
                    VStack(spacing: 8) {
                        Text(expense.formattedAmount)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.primary)

                        Text(expense.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)

                    // Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(
                            icon: "text.alignleft",
                            title: "Title",
                            value: expense.wrappedTitle
                        )

                        if let category = expense.category {
                            DetailRow(
                                icon: category.wrappedIcon,
                                iconColor: category.color,
                                title: "Category",
                                value: category.wrappedName
                            )
                        }

                        DetailRow(
                            icon: "calendar",
                            title: "Date",
                            value: expense.formattedDate
                        )

                        if !expense.wrappedNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.blue)
                                    Text("Notes")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Text(expense.wrappedNotes)
                                    .font(.body)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit Expense", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Expense", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Expense Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                AddExpenseView(expense: expense)
            }
            .alert("Delete Expense", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteExpense(expense)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this expense? This action cannot be undone.")
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    var iconColor: Color = .blue
    let title: String
    let value: String

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    let context = DataController.shared.container.viewContext
    let expense = Expense(context: context)
    expense.id = UUID()
    expense.title = "Coffee at Starbucks"
    expense.amount = 5.99
    expense.date = Date()
    expense.notes = "Morning coffee with a friend"

    return ExpenseDetailView(expense: expense)
        .environmentObject(ExpenseViewModel(context: context))
}
