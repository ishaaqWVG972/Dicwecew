


import SwiftUI
import Charts

struct CategoryWiseSpendingView: View {
    @ObservedObject var viewModel: TransactionViewModel

    var body: some View {
        NavigationView {
            VStack {
                // Date Navigation
                DateNavigationView(viewModel: viewModel)

                // Displaying a message if there are no transactions
                if viewModel.filteredTransactions.isEmpty {
                    Text("No data available for this period")
                        .padding()
                } else {
                    // Chart for spending in each category
                    SpendingChartView(spendingData: viewModel.categoryWiseSpending())
                }
            }
            .navigationBarTitle("Category Spending", displayMode: .inline)
            .padding()
        }
        .onAppear {
            viewModel.fetchTransactionsForDateRange()
        }
    }

    private struct DateNavigationView: View {
        @ObservedObject var viewModel: TransactionViewModel

        var body: some View {
            HStack {
                NavigationButton(action: viewModel.moveToPreviousMonth, label: "arrow.left", isEnabled: true)
                Spacer()
                Text(dateRangeText(for: viewModel))
                    .font(.headline)
                Spacer()
                NavigationButton(action: viewModel.moveToNextMonth, label: "arrow.right", isEnabled: viewModel.canMoveToNextMonth())
            }
            .padding(.horizontal)
        }

        private func dateRangeText(for viewModel: TransactionViewModel) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: viewModel.startDate) + " - " + formatter.string(from: viewModel.endDate)
        }

        private struct NavigationButton: View {
            let action: () -> Void
            let label: String
            let isEnabled: Bool

            var body: some View {
                Button(action: action) {
                    Image(systemName: label)
                        .foregroundColor(isEnabled ? .blue : .gray)
                }
                .disabled(!isEnabled)
            }
        }
    }

    private struct SpendingChartView: View {
        var spendingData: [CategorySpending]
        var colors: [Color] = [.blue, .green, .orange, .pink, .purple, .red, .yellow]

        var body: some View {
            Chart {
                ForEach(Array(spendingData.enumerated()), id: \.element.id) { index, spending in
                    BarMark(
                        x: .value("Category", spending.category),
                        y: .value("Amount", spending.amount)
                    )
                    .foregroundStyle(colors[index % colors.count])
                }
            }
            .frame(height: 250)
        }
    }
}

struct CategoryWiseSpendingView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryWiseSpendingView(viewModel: TransactionViewModel())
    }
}
