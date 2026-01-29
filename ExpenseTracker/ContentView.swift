import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ExpenseViewModel

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
    }
}

#Preview {
    ContentView()
        .environmentObject(ExpenseViewModel(context: DataController.shared.container.viewContext))
}
