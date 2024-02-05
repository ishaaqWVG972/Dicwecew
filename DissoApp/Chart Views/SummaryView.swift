import SwiftUI

struct SummaryView: View {
    @ObservedObject var viewModel: TransactionViewModel

    var body: some View {
        VStack {
            if let topCategory = viewModel.topExpenseCategories().first {
                VStack(alignment: .leading) {
                    Text("Top Category: \(topCategory.category)")
                        .font(.headline)
                    Text("Total Spending in \(topCategory.category): £\(topCategory.amount, specifier: "%.2f")")
                        .font(.subheadline)
                }
                .padding()
            } else {
                Text("No spending data available")
                    .padding()
            }
            
            Text("Total Spending: £\(viewModel.transactions.map { $0.totalPrice }.reduce(0, +), specifier: "%.2f")")
                .font(.title)
        }
        .onAppear {
            viewModel.fetchTransactionsFromDB() // Load transactions when the view appears
        }
    }
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView(viewModel: TransactionViewModel())
    }
}
