import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var categories: [ExpenseCategory]

    @State private var selectedPeriod: TimePeriod = .thisMonth

    var filteredExpenses: [Expense] {
        expenses.filter { $0.date >= selectedPeriod.startDate }
    }

    var totalSpent: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var categoryBreakdown: [(category: ExpenseCategory, total: Double, percentage: Double)] {
        var totals: [ExpenseCategory: Double] = [:]

        for expense in filteredExpenses {
            if let category = expense.category {
                totals[category, default: 0] += expense.amount
            }
        }

        let total = totalSpent
        return totals.map { category, amount in
            (category, amount, total > 0 ? amount / total : 0)
        }.sorted { $0.total > $1.total }
    }

    var dailyExpenses: [(date: Date, amount: Double)] {
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Period Picker
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Total Card
                    VStack(spacing: 8) {
                        Text("Total Spent")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(totalSpent))
                            .font(.system(size: 40, weight: .bold))
                        Text("\(filteredExpenses.count) transactions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 10)
                    )
                    .padding(.horizontal)

                    if !categoryBreakdown.isEmpty {
                        // Pie Chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text("By Category")
                                .font(.headline)
                                .padding(.horizontal)

                            Chart(categoryBreakdown, id: \.category.id) { item in
                                SectorMark(
                                    angle: .value("Amount", item.total),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(item.category.color)
                                .cornerRadius(4)
                            }
                            .frame(height: 200)
                            .padding(.horizontal)

                            // Legend
                            VStack(spacing: 12) {
                                ForEach(categoryBreakdown, id: \.category.id) { item in
                                    HStack {
                                        Circle()
                                            .fill(item.category.color)
                                            .frame(width: 12, height: 12)
                                        Text(item.category.name)
                                            .font(.subheadline)
                                        Spacer()
                                        Text(formatCurrency(item.total))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("(\(Int(item.percentage * 100))%)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 10)
                        )
                        .padding(.horizontal)
                    }

                    if !dailyExpenses.isEmpty {
                        // Daily Trend Chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Daily Spending")
                                .font(.headline)
                                .padding(.horizontal)

                            Chart(dailyExpenses, id: \.date) { item in
                                BarMark(
                                    x: .value("Date", item.date, unit: .day),
                                    y: .value("Amount", item.amount)
                                )
                                .foregroundStyle(Color.blue.gradient)
                                .cornerRadius(4)
                            }
                            .frame(height: 200)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 10)
                        )
                        .padding(.horizontal)
                    }

                    if filteredExpenses.isEmpty {
                        ContentUnavailableView(
                            "No Data",
                            systemImage: "chart.pie",
                            description: Text("Add expenses to see statistics")
                        )
                        .padding(.top, 40)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Statistics")
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = UserDefaults.standard.string(forKey: "currencyCode") ?? "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}
