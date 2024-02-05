
import SwiftUI

struct BudgetCreationOverlay: View {
    @Binding var showModal: Bool
    @ObservedObject var viewModel: TransactionViewModel
    @State private var selectedCategory: String = "Total"
    @State private var budgetAmount: String = ""
    @State private var selectedTimeFrame: BudgetTimeFrame = .total
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var categories: [Category] = []

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        Text("Total").tag("Total")
                        ForEach(categories, id: \.id) { category in
                            Text(category.name).tag(category.name)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Budget Amount")) {
                    TextField("Enter Amount", text: $budgetAmount)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Time Frame")) {
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        Text("Week").tag(BudgetTimeFrame.week)
                        Text("Month").tag(BudgetTimeFrame.month)
//                        Text("Total").tag(BudgetTimeFrame.total)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                if selectedTimeFrame != .total {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }

                Section {
                    Button("Save Budget") {
                        saveBudget()
                    }
                }
            }
            .navigationBarTitle("Create Budget", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { showModal = false })
            .onAppear(perform: fetchCategories)
        }
    }

    private func fetchCategories() {
        viewModel.fetchCategories { fetchedCategories in
            self.categories = fetchedCategories
        }
    }

    private func saveBudget() {
        if let amount = Double(budgetAmount) {
            let budgetDetails = BudgetDetails(limit: amount, timeFrame: selectedTimeFrame, startDate: startDate, endDate: endDate)
            if selectedCategory == "Total" {
                viewModel.setTotalBudget(amount, startDate: startDate, endDate: endDate)
            } else {
                viewModel.setCategoryBudget(selectedCategory, amount: amount, timeFrame: selectedTimeFrame, startDate: startDate, endDate: endDate)
            }
            showModal = false
        }
       
    }
}

struct BudgetCreationOverlay_Previews: PreviewProvider {
    static var previews: some View {
        BudgetCreationOverlay(showModal: .constant(true), viewModel: TransactionViewModel())
    }
}


