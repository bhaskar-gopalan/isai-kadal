import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var viewModel: ExpenseViewModel
    @State private var selectedChartType: ChartType = .category

    enum ChartType: String, CaseIterable {
        case category = "By Category"
        case daily = "Daily"
        case monthly = "Monthly"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Total Summary
                    VStack(spacing: 8) {
                        Text("Total Expenses")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(viewModel.formattedTotalExpenses)
                            .font(.system(size: 40, weight: .bold))
                        Text(viewModel.selectedPeriod.rawValue)
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
                    .padding(.horizontal)

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

                    // Chart Type Picker
                    Picker("Chart Type", selection: $selectedChartType) {
                        ForEach(ChartType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Chart View
                    Group {
                        switch selectedChartType {
                        case .category:
                            CategoryPieChart(data: viewModel.expensesByCategory)
                        case .daily:
                            DailyBarChart(data: viewModel.getDailyExpenses())
                        case .monthly:
                            MonthlyBarChart(data: viewModel.getMonthlyExpenses())
                        }
                    }
                    .frame(height: 300)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)

                    // Category Breakdown
                    if selectedChartType == .category && !viewModel.expensesByCategory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category Breakdown")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(viewModel.expensesByCategory, id: \.category.id) { item in
                                CategoryBreakdownRow(
                                    category: item.category,
                                    total: item.total,
                                    percentage: item.percentage
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Statistics")
            .onAppear {
                viewModel.fetchData()
            }
        }
    }
}

struct CategoryPieChart: View {
    let data: [(category: Category, total: Double, percentage: Double)]

    var body: some View {
        if data.isEmpty {
            ContentUnavailableView(
                "No Data",
                systemImage: "chart.pie",
                description: Text("Add some expenses to see statistics")
            )
        } else {
            Chart(data, id: \.category.id) { item in
                SectorMark(
                    angle: .value("Amount", item.total),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.5
                )
                .foregroundStyle(item.category.color)
                .cornerRadius(5)
            }
        }
    }
}

struct DailyBarChart: View {
    let data: [(date: Date, total: Double)]

    var body: some View {
        if data.allSatisfy({ $0.total == 0 }) {
            ContentUnavailableView(
                "No Data",
                systemImage: "chart.bar",
                description: Text("No expenses in the selected period")
            )
        } else {
            Chart(data, id: \.date) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Amount", item.total)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
        }
    }
}

struct MonthlyBarChart: View {
    let data: [(month: String, total: Double)]

    var body: some View {
        if data.allSatisfy({ $0.total == 0 }) {
            ContentUnavailableView(
                "No Data",
                systemImage: "chart.bar",
                description: Text("No expenses in the selected period")
            )
        } else {
            Chart(data, id: \.month) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Amount", item.total)
                )
                .foregroundStyle(Color.green.gradient)
                .cornerRadius(4)
            }
        }
    }
}

struct CategoryBreakdownRow: View {
    let category: Category
    let total: Double
    let percentage: Double

    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: total)) ?? "$0.00"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(category.color)
                    .frame(width: 40, height: 40)
                Image(systemName: category.wrappedIcon)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.wrappedName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)

                        Rectangle()
                            .fill(category.color)
                            .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedTotal)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    StatisticsView()
        .environmentObject(ExpenseViewModel(context: DataController.shared.container.viewContext))
}
