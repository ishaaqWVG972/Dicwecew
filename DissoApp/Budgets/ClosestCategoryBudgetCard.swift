import SwiftUI

struct ClosestCategoryBudgetCard: View {
    @ObservedObject var viewModel: TransactionViewModel
    var category: String

    var body: some View {
        if let budgetDetails = viewModel.budget.categories[category] {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(category) Budget").font(.headline)
                HStack {
                    VStack(alignment: .leading) {
                        Text("Budget: £\(budgetDetails.limit, specifier: "%.2f")")
                        Text(viewModel.remainingDaysForBudget(category: category))
                        Text("Remaining: £\(viewModel.calculateRemainingBudget(for: category), specifier: "%.2f")")
                    }
                    Spacer()
                    ProgressBar(value: viewModel.calculateSpentPercentage(for: category), maxValue: 1)
                        .frame(height: 20)
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
    }
}
