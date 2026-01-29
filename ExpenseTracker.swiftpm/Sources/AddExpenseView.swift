import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    var expense: Expense?

    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var showingCategoryPicker = false

    var isEditing: Bool { expense != nil }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(amount) != nil &&
        Double(amount)! > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)

                    HStack {
                        Text(currencySymbol)
                            .foregroundColor(.secondary)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Category") {
                    Button {
                        showingCategoryPicker = true
                    } label: {
                        HStack {
                            if let category = selectedCategory {
                                ZStack {
                                    Circle()
                                        .fill(category.color.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: category.icon)
                                        .foregroundColor(category.color)
                                        .font(.system(size: 14))
                                }
                                Text(category.name)
                                    .foregroundColor(.primary)
                            } else {
                                Image(systemName: "folder")
                                    .foregroundColor(.secondary)
                                Text("Select Category")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }

                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(isEditing ? "Edit Expense" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Add") {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory)
            }
            .onAppear {
                if let expense = expense {
                    title = expense.title
                    amount = String(format: "%.2f", expense.amount)
                    date = expense.date
                    notes = expense.notes
                    selectedCategory = expense.category
                }
            }
        }
    }

    private var currencySymbol: String {
        let code = UserDefaults.standard.string(forKey: "currencyCode") ?? "USD"
        let locale = NSLocale(localeIdentifier: code)
        return locale.displayName(forKey: .currencySymbol, value: code) ?? "$"
    }

    private func saveExpense() {
        guard let amountValue = Double(amount) else { return }

        if let expense = expense {
            expense.title = title.trimmingCharacters(in: .whitespaces)
            expense.amount = amountValue
            expense.date = date
            expense.notes = notes
            expense.category = selectedCategory
        } else {
            let newExpense = Expense(
                title: title.trimmingCharacters(in: .whitespaces),
                amount: amountValue,
                date: date,
                notes: notes,
                category: selectedCategory
            )
            modelContext.insert(newExpense)
        }

        try? modelContext.save()
        dismiss()
    }
}

struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    @Binding var selectedCategory: ExpenseCategory?

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedCategory = nil
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                        Text("No Category")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }

                ForEach(categories) { category in
                    Button {
                        selectedCategory = category
                        dismiss()
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(category.color.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                            }
                            Text(category.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCategory?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
