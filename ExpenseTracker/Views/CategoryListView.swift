import SwiftUI

struct CategoryListView: View {
    @EnvironmentObject var viewModel: ExpenseViewModel
    @State private var showingAddCategory = false
    @State private var categoryToEdit: Category?

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.categories) { category in
                    CategoryRow(category: category)
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
            .onAppear {
                viewModel.fetchData()
            }
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteCategory(viewModel.categories[index])
        }
    }
}

struct CategoryRow: View {
    let category: Category

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(category.color)
                    .frame(width: 48, height: 48)
                Image(systemName: category.wrappedIcon)
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.wrappedName)
                    .font(.headline)

                HStack {
                    Text("\(category.expensesArray.count) expenses")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if category.budget > 0 {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("Budget: \(category.formattedBudget)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(category.formattedTotalExpenses)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if category.budget > 0 {
                    BudgetIndicator(progress: category.budgetProgress, isOverBudget: category.isOverBudget)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct BudgetIndicator: View {
    let progress: Double
    let isOverBudget: Bool

    var body: some View {
        HStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)

                    Rectangle()
                        .fill(isOverBudget ? Color.red : Color.green)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(width: 60, height: 4)

            Text(String(format: "%.0f%%", progress * 100))
                .font(.caption2)
                .foregroundColor(isOverBudget ? .red : .secondary)
        }
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ExpenseViewModel

    @State private var name: String = ""
    @State private var selectedIcon: String = "folder"
    @State private var selectedColor: String = "#007AFF"
    @State private var budget: String = ""

    var category: Category?
    var isEditing: Bool { category != nil }

    let iconOptions = [
        "folder", "cart.fill", "fork.knife", "car.fill", "house.fill",
        "heart.fill", "gift.fill", "airplane", "bus.fill", "tram.fill",
        "bicycle", "figure.walk", "bag.fill", "creditcard.fill", "banknote.fill",
        "phone.fill", "tv.fill", "gamecontroller.fill", "headphones", "music.note",
        "book.fill", "graduationcap.fill", "briefcase.fill", "wrench.fill", "hammer.fill",
        "paintbrush.fill", "scissors", "bandage.fill", "pills.fill", "cross.fill",
        "leaf.fill", "drop.fill", "flame.fill", "bolt.fill", "cloud.fill",
        "sun.max.fill", "moon.fill", "star.fill", "sparkles", "pawprint.fill"
    ]

    let colorOptions = [
        "#007AFF", "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE",
        "#85C1E9", "#F8B500", "#FF6F61", "#6B5B95", "#88B04B",
        "#F7CAC9", "#92A8D1", "#955251", "#B565A7", "#009B77"
    ]

    init(category: Category? = nil) {
        self.category = category
        if let category = category {
            _name = State(initialValue: category.wrappedName)
            _selectedIcon = State(initialValue: category.wrappedIcon)
            _selectedColor = State(initialValue: category.wrappedColorHex)
            _budget = State(initialValue: category.budget > 0 ? String(format: "%.2f", category.budget) : "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category Name") {
                    TextField("Name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon ? Color(hex: selectedColor) : Color.gray.opacity(0.2))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: icon)
                                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                                        .font(.system(size: 16))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 28, height: 28)

                                    if selectedColor == color {
                                        Circle()
                                            .stroke(Color.primary, lineWidth: 2)
                                            .frame(width: 34, height: 34)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Monthly Budget (Optional)") {
                    HStack {
                        Text(Locale.current.currencySymbol ?? "$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $budget)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    HStack {
                        Text("Preview")
                            .foregroundColor(.secondary)
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColor))
                                .frame(width: 44, height: 44)
                            Image(systemName: selectedIcon)
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        Text(name.isEmpty ? "Category Name" : name)
                            .fontWeight(.medium)
                    }
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
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveCategory() {
        let budgetValue = Double(budget) ?? 0

        if let category = category {
            viewModel.updateCategory(
                category,
                name: name.trimmingCharacters(in: .whitespaces),
                icon: selectedIcon,
                colorHex: selectedColor,
                budget: budgetValue
            )
        } else {
            viewModel.addCategory(
                name: name.trimmingCharacters(in: .whitespaces),
                icon: selectedIcon,
                colorHex: selectedColor,
                budget: budgetValue
            )
        }

        dismiss()
    }
}

#Preview {
    CategoryListView()
        .environmentObject(ExpenseViewModel(context: DataController.shared.container.viewContext))
}
