import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var categories: [ExpenseCategory]

    @State private var showingAddExpense = false
    @State private var searchText = ""
    @State private var selectedPeriod: TimePeriod = .thisMonth

    var filteredExpenses: [Expense] {
        expenses.filter { expense in
            let matchesSearch = searchText.isEmpty ||
                expense.title.localizedCaseInsensitiveContains(searchText) ||
                (expense.category?.name.localizedCaseInsensitiveContains(searchText) ?? false)

            let matchesPeriod = expense.date >= selectedPeriod.startDate

            return matchesSearch && matchesPeriod
        }
    }

    var totalAmount: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var groupedExpenses: [(date: Date, expenses: [Expense])] {
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
        return grouped.map { ($0.key, $0.value) }.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary Card
                VStack(spacing: 8) {
                    Text("Total Spent")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(totalAmount))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    Text(selectedPeriod.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding()

                // Period Picker
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Expense List
                if filteredExpenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses",
                        systemImage: "tray",
                        description: Text("Tap + to add your first expense")
                    )
                } else {
                    List {
                        ForEach(groupedExpenses, id: \.date) { group in
                            Section(header: Text(formatDateHeader(group.date))) {
                                ForEach(group.expenses) { expense in
                                    ExpenseRowView(expense: expense)
                                }
                                .onDelete { indexSet in
                                    deleteExpenses(from: group.expenses, at: indexSet)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Expenses")
            .searchable(text: $searchText, prompt: "Search expenses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddExpense = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
        }
    }

    private func deleteExpenses(from expenses: [Expense], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(expenses[index])
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = UserDefaults.standard.string(forKey: "currencyCode") ?? "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill((expense.category?.color ?? .gray).opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: expense.category?.icon ?? "questionmark.circle")
                        .foregroundColor(expense.category?.color ?? .gray)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.title)
                        .font(.body)
                        .foregroundColor(.primary)
                    if let category = expense.category {
                        Text(category.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(expense.formattedAmount)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showingDetail) {
            ExpenseDetailView(expense: expense)
        }
    }
}
