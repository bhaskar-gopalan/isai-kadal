import SwiftUI

struct SettingsView: View {
    @AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("dailyReminderTime") private var dailyReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @AppStorage("defaultCategory") private var defaultCategory: String = ""
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    @State private var showingExportSheet = false
    @State private var showingResetAlert = false

    let currencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "INR", "CNY", "BRL", "MXN"]
    let appearanceModes = ["system", "light", "dark"]

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencies, id: \.self) { currency in
                            Text(currencySymbol(for: currency) + " " + currency).tag(currency)
                        }
                    }

                    Picker("Appearance", selection: $appearanceMode) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }

                Section("Notifications") {
                    Toggle("Daily Reminder", isOn: $enableNotifications)

                    if enableNotifications {
                        DatePicker("Reminder Time", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("Data") {
                    Button {
                        showingExportSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Data")
                        }
                    }

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
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        Text("Expense Tracker")
                            .font(.headline)
                        Text("Track your expenses with ease")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
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
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView()
            }
        }
    }

    private func currencySymbol(for code: String) -> String {
        let locale = NSLocale(localeIdentifier: code)
        return locale.displayName(forKey: .currencySymbol, value: code) ?? code
    }

    private func resetAllData() {
        let dataController = DataController.shared
        let context = dataController.container.viewContext

        // Delete all expenses
        let expenseRequest: NSFetchRequest<NSFetchRequestResult> = Expense.fetchRequest()
        let expenseDeleteRequest = NSBatchDeleteRequest(fetchRequest: expenseRequest)

        // Delete all categories
        let categoryRequest: NSFetchRequest<NSFetchRequestResult> = Category.fetchRequest()
        let categoryDeleteRequest = NSBatchDeleteRequest(fetchRequest: categoryRequest)

        do {
            try context.execute(expenseDeleteRequest)
            try context.execute(categoryDeleteRequest)
            try context.save()
        } catch {
            print("Error resetting data: \(error)")
        }
    }
}

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ExpenseViewModel

    @State private var exportFormat: ExportFormat = .csv
    @State private var includePeriod: TimePeriod = .all
    @State private var isExporting = false

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Date Range") {
                    Picker("Period", selection: $includePeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                }

                Section {
                    Button {
                        exportData()
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Export")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isExporting)
                }

                Section {
                    Text("Your expense data will be exported as a \(exportFormat.rawValue) file that you can save or share.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func exportData() {
        isExporting = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isExporting = false
            dismiss()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ExpenseViewModel(context: DataController.shared.container.viewContext))
}
