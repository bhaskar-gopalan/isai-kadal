import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode: String = "USD"

    @State private var showingResetAlert = false

    let currencies = [
        ("USD", "🇺🇸 US Dollar"),
        ("EUR", "🇪🇺 Euro"),
        ("GBP", "🇬🇧 British Pound"),
        ("JPY", "🇯🇵 Japanese Yen"),
        ("CAD", "🇨🇦 Canadian Dollar"),
        ("AUD", "🇦🇺 Australian Dollar"),
        ("INR", "🇮🇳 Indian Rupee"),
        ("CNY", "🇨🇳 Chinese Yuan"),
        ("BRL", "🇧🇷 Brazilian Real"),
        ("MXN", "🇲🇽 Mexican Peso")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Currency") {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencies, id: \.0) { code, name in
                            Text(name).tag(code)
                        }
                    }
                }

                Section("Data Management") {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Reset All Data")
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Platform")
                        Spacer()
                        Text("iOS 17+")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.blue)

                        Text("Expense Tracker")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Track your expenses with ease")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Built with SwiftUI & SwiftData")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Data", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all your expenses and categories. This action cannot be undone.")
            }
        }
    }

    private func resetAllData() {
        do {
            try modelContext.delete(model: Expense.self)
            try modelContext.delete(model: ExpenseCategory.self)
        } catch {
            print("Error resetting data: \(error)")
        }
    }
}
