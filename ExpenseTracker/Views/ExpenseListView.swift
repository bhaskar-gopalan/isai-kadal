import SwiftUI

struct ExpenseListView: View {
    @EnvironmentObject var viewModel: ExpenseViewModel
    @State private var showingAddExpense = false
    @State private var selectedExpense: Expense?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary Card
                SummaryCard(
                    total: viewModel.formattedTotalExpenses,
                    period: viewModel.selectedPeriod.rawValue
                )
                .padding()

                // Period Picker
                Picker("Period", selection: $viewModel.selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: viewModel.selectedPeriod) { _, newValue in
                    viewModel.changePeriod(to: newValue)
                }

                // Expense List
                if viewModel.filteredExpenses.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(viewModel.sortedDates, id: \.self) { date in
                            Section(header: Text(formatDate(date))) {
                                if let dayExpenses = viewModel.expensesByDate[date] {
                                    ForEach(dayExpenses) { expense in
                                        ExpenseRowView(expense: expense)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                selectedExpense = expense
                                            }
                                    }
                                    .onDelete { offsets in
                                        viewModel.deleteExpenses(at: offsets, from: dayExpenses)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Expenses")
            .searchable(text: $viewModel.searchText, prompt: "Search expenses")
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
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailView(expense: expense)
            }
            .onAppear {
                viewModel.fetchData()
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
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

struct SummaryCard: View {
    let total: String
    let period: String

    var body: some View {
        VStack(spacing: 8) {
            Text("Total Spending")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(total)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.primary)
            Text(period)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("No Expenses")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Tap the + button to add your first expense")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ExpenseListView()
        .environmentObject(ExpenseViewModel(context: DataController.shared.container.viewContext))
}
