import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ExpenseViewModel

    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var selectedCategory: Category?
    @State private var showingCategoryPicker = false

    var expense: Expense?
    var isEditing: Bool { expense != nil }

    init(expense: Expense? = nil) {
        self.expense = expense
        if let expense = expense {
            _title = State(initialValue: expense.wrappedTitle)
            _amount = State(initialValue: String(format: "%.2f", expense.amount))
            _date = State(initialValue: expense.wrappedDate)
            _notes = State(initialValue: expense.wrappedNotes)
            _selectedCategory = State(initialValue: expense.category)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)

                    HStack {
                        Text(Locale.current.currencySymbol ?? "$")
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
                                        .fill(category.color)
                                        .frame(width: 32, height: 32)
                                    Image(systemName: category.wrappedIcon)
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                }
                                Text(category.wrappedName)
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
            .navigationTitle(isEditing ? "Edit Expense" : "New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(!isValidInput)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory)
            }
        }
    }

    private var isValidInput: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(amount) != nil &&
        Double(amount)! > 0
    }

    private func saveExpense() {
        guard let amountValue = Double(amount) else { return }

        if let expense = expense {
            viewModel.updateExpense(
                expense,
                title: title.trimmingCharacters(in: .whitespaces),
                amount: amountValue,
                date: date,
                notes: notes.isEmpty ? nil : notes,
                category: selectedCategory
            )
        } else {
            viewModel.addExpense(
                title: title.trimmingCharacters(in: .whitespaces),
                amount: amountValue,
                date: date,
                notes: notes.isEmpty ? nil : notes,
                category: selectedCategory
            )
        }

        dismiss()
    }
}

struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ExpenseViewModel
    @Binding var selectedCategory: Category?

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.categories) { category in
                    Button {
                        selectedCategory = category
                        dismiss()
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 36, height: 36)
                                Image(systemName: category.wrappedIcon)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            }

                            Text(category.wrappedName)
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

#Preview {
    AddExpenseView()
        .environmentObject(ExpenseViewModel(context: DataController.shared.container.viewContext))
}
