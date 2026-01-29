import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var hasSetupCategories = false

    var body: some View {
        TabView {
            ExpenseListView()
                .tabItem {
                    Label("Expenses", systemImage: "list.bullet.rectangle")
                }

            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.pie")
                }

            CategoryListView()
                .tabItem {
                    Label("Categories", systemImage: "folder")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.blue)
        .onAppear {
            setupDefaultCategoriesIfNeeded()
        }
    }

    private func setupDefaultCategoriesIfNeeded() {
        guard !hasSetupCategories else { return }

        let descriptor = FetchDescriptor<ExpenseCategory>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0

        if count == 0 {
            for categoryData in DefaultCategories.categories {
                let category = ExpenseCategory(
                    name: categoryData.name,
                    icon: categoryData.icon,
                    colorHex: categoryData.colorHex
                )
                modelContext.insert(category)
            }
            try? modelContext.save()
        }

        hasSetupCategories = true
    }
}
