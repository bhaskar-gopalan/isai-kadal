import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    @State private var showingAddCategory = false
    @State private var categoryToEdit: ExpenseCategory?

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    CategoryRowView(category: category)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            categoryToEdit = category
                        }
                }
                .onDelete(perform: deleteCategories)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
            .sheet(item: $categoryToEdit) { category in
                AddCategoryView(category: category)
            }
            .overlay {
                if categories.isEmpty {
                    ContentUnavailableView(
                        "No Categories",
                        systemImage: "folder",
                        description: Text("Tap + to add a category")
                    )
                }
            }
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
    }
}

struct CategoryRowView: View {
    let category: ExpenseCategory

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.body)
                    .fontWeight(.medium)

                if category.budget > 0 {
                    HStack(spacing: 8) {
                        ProgressView(value: category.budgetProgress)
                            .tint(category.budgetProgress >= 1 ? .red : category.color)
                            .frame(width: 100)

                        Text("\(formatCurrency(category.totalSpent)) / \(formatCurrency(category.budget))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No budget set")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = UserDefaults.standard.string(forKey: "currencyCode") ?? "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var category: ExpenseCategory?

    @State private var name: String = ""
    @State private var selectedIcon: String = "folder"
    @State private var selectedColor: String = "007AFF"
    @State private var budget: String = ""

    var isEditing: Bool { category != nil }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    let icons = [
        "fork.knife", "car.fill", "bag.fill", "tv.fill", "bolt.fill",
        "heart.fill", "airplane", "book.fill", "sparkles", "house.fill",
        "gift.fill", "creditcard.fill", "briefcase.fill", "gamecontroller.fill",
        "music.note", "film.fill", "phone.fill", "wifi", "cart.fill", "folder"
    ]

    let colors = [
        "FF6B6B", "4ECDC4", "45B7D1", "96CEB4", "FFEAA7",
        "DDA0DD", "98D8C8", "F7DC6F", "BB8FCE", "95A5A6",
        "007AFF", "34C759", "FF9500", "FF2D55", "AF52DE"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category Name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.2) : Color.gray.opacity(0.1))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: icon)
                                        .foregroundColor(selectedIcon == icon ? Color(hex: selectedColor) : .gray)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 36, height: 36)
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.caption.bold())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Monthly Budget (Optional)") {
                    HStack {
                        Text(currencySymbol)
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $budget)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: selectedColor).opacity(0.2))
                                    .frame(width: 64, height: 64)
                                Image(systemName: selectedIcon)
                                    .foregroundColor(Color(hex: selectedColor))
                                    .font(.system(size: 28))
                            }
                            Text(name.isEmpty ? "Category Name" : name)
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Add") {
                        saveCategory()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let category = category {
                    name = category.name
                    selectedIcon = category.icon
                    selectedColor = category.colorHex
                    if category.budget > 0 {
                        budget = String(format: "%.2f", category.budget)
                    }
                }
            }
        }
    }

    private var currencySymbol: String {
        let code = UserDefaults.standard.string(forKey: "currencyCode") ?? "USD"
        let locale = NSLocale(localeIdentifier: code)
        return locale.displayName(forKey: .currencySymbol, value: code) ?? "$"
    }

    private func saveCategory() {
        let budgetValue = Double(budget) ?? 0

        if let category = category {
            category.name = name.trimmingCharacters(in: .whitespaces)
            category.icon = selectedIcon
            category.colorHex = selectedColor
            category.budget = budgetValue
        } else {
            let newCategory = ExpenseCategory(
                name: name.trimmingCharacters(in: .whitespaces),
                icon: selectedIcon,
                colorHex: selectedColor,
                budget: budgetValue
            )
            modelContext.insert(newCategory)
        }

        try? modelContext.save()
        dismiss()
    }
}
