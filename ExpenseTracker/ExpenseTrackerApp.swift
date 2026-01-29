import SwiftUI

@main
struct ExpenseTrackerApp: App {
    @StateObject private var dataController = DataController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(ExpenseViewModel(context: dataController.container.viewContext))
        }
    }
}
