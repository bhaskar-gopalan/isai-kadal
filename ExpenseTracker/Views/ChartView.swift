import SwiftUI
import Charts

struct SpendingTrendChart: View {
    let data: [(date: Date, total: Double)]
    let color: Color

    var body: some View {
        Chart(data, id: \.date) { item in
            LineMark(
                x: .value("Date", item.date),
                y: .value("Amount", item.total)
            )
            .foregroundStyle(color)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Date", item.date),
                y: .value("Amount", item.total)
            )
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [color.opacity(0.3), color.opacity(0.0)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
    }
}

struct BudgetProgressChart: View {
    let spent: Double
    let budget: Double
    let color: Color

    var progress: Double {
        guard budget > 0 else { return 0 }
        return min(spent / budget, 1.0)
    }

    var isOverBudget: Bool {
        spent > budget && budget > 0
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isOverBudget ? Color.red : color,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", progress * 100))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("of budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ComparisonBarChart: View {
    struct ComparisonData: Identifiable {
        let id = UUID()
        let label: String
        let current: Double
        let previous: Double
    }

    let data: [ComparisonData]

    var body: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("Category", item.label),
                    y: .value("Current", item.current)
                )
                .foregroundStyle(Color.blue)
                .position(by: .value("Type", "Current"))

                BarMark(
                    x: .value("Category", item.label),
                    y: .value("Previous", item.previous)
                )
                .foregroundStyle(Color.gray.opacity(0.5))
                .position(by: .value("Type", "Previous"))
            }
        }
        .chartLegend(position: .bottom)
    }
}

struct MiniSparklineChart: View {
    let data: [Double]
    let color: Color

    var body: some View {
        Chart(Array(data.enumerated()), id: \.offset) { index, value in
            LineMark(
                x: .value("Index", index),
                y: .value("Value", value)
            )
            .foregroundStyle(color)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Index", index),
                y: .value("Value", value)
            )
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [color.opacity(0.3), color.opacity(0.0)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

#Preview {
    VStack(spacing: 20) {
        SpendingTrendChart(
            data: [
                (Date().addingTimeInterval(-6 * 86400), 50),
                (Date().addingTimeInterval(-5 * 86400), 75),
                (Date().addingTimeInterval(-4 * 86400), 30),
                (Date().addingTimeInterval(-3 * 86400), 90),
                (Date().addingTimeInterval(-2 * 86400), 45),
                (Date().addingTimeInterval(-1 * 86400), 60),
                (Date(), 80)
            ],
            color: .blue
        )
        .frame(height: 200)

        BudgetProgressChart(spent: 750, budget: 1000, color: .green)
            .frame(width: 150, height: 150)

        MiniSparklineChart(
            data: [50, 75, 30, 90, 45, 60, 80],
            color: .purple
        )
        .frame(height: 50)
    }
    .padding()
}
