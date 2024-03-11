import SwiftUI

struct ProductImpactView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @State private var productName: String = ""
    @State private var productPrice: String = ""
    @State private var selectedBudgetCategory: String = "Total"
    @State private var impactMessage: String? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Product Details")) {
                    TextField("Product Name", text: $productName)
                    TextField("Product Price", text: $productPrice)
                        .keyboardType(.decimalPad)
                    Button("Add Product") {
                        addProduct()
                        productName = ""
                        productPrice = ""
                    }
                }

                Section(header: Text("Products to Add")) {
                    ForEach(viewModel.productEntries) { product in
                        Text("\(product.name) - \(product.price)")
                    }
                    .onDelete(perform: removeProducts)
                }

                Section(header: Text("Select Budget")) {
                    Picker("Budget", selection: $selectedBudgetCategory) {
                        Text("Total").tag("Total")
                        ForEach(viewModel.budgetsList, id: \.category) { budgetItem in
                            Text(budgetItem.category).tag(budgetItem.category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                if let message = impactMessage {
                    Section(header: Text("Potential Impact")) {
                        Text(message).foregroundColor(.red)
                    }
                }

                Button("Calculate Total Impact") {
                    calculateTotalImpactOnBudget()
                }
            }
            .navigationTitle("Add Product Impact")
            .navigationBarItems(trailing: EditButton())
        }
    }

    private func addProduct() {
        guard !productName.isEmpty, !productPrice.isEmpty else {
            // Consider showing an error message if this validation fails
            return
        }
        let newProduct = ProductEntry(name: productName, price: productPrice)
        viewModel.productEntries.append(newProduct)
    }

    private func removeProducts(at offsets: IndexSet) {
        viewModel.productEntries.remove(atOffsets: offsets)
    }

    private func calculateTotalImpactOnBudget() {
        let totalImpactPrice = viewModel.productEntries.reduce(0.0) { result, productEntry in
            result + (Double(productEntry.price) ?? 0.0)
        }
        
        // Fetch the current budget limit and the amount already spent.
        let currentBudgetLimit = viewModel.budget.categories[selectedBudgetCategory]?.limit ?? 0
        let currentSpent = viewModel.budget.spent[selectedBudgetCategory] ?? 0
        let currentRemainingBudget = currentBudgetLimit - currentSpent
        
        // Calculate the new remaining budget after factoring in the price of the new products.
        let newRemainingBudget = currentRemainingBudget - totalImpactPrice
        
        // Prepare the impact message string based on whether the new purchases exceed the remaining budget.
        let impactMessageString = newRemainingBudget < 0 ?
            "These purchases will exceed your remaining budget by \(abs(newRemainingBudget))" :
            "Remaining budget after purchases: \(newRemainingBudget)"
        
        // Update the impact message to include both the current remaining budget before the new purchases and the impact of these purchases.
        impactMessage = """
        Current Remaining Budget: \(currentRemainingBudget)
        \(impactMessageString)
        """
    }

}
