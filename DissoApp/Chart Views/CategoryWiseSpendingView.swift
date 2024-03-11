import SwiftUI
import Charts

struct CategoryWiseSpendingView: View {
    @ObservedObject var viewModel: TransactionViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    DateNavigationView(viewModel: viewModel)

                    if !viewModel.filteredTransactions.isEmpty {
                        SpendingChartView(spendingData: viewModel.categoryWiseSpending())
                            .frame(height: 250) // Defined chart height
                            .padding(.top) // Added padding for visual separation
                    } else {
                        Text("No data available for this period")
                            .font(.subheadline) // Reduced font size for high-fidelity
                            .padding()
                    }

                    // Summary Cards below the Chart
                    let formattedTotalSpent = String(format: "£%.2f", viewModel.totalSpentInCurrentPeriod())
                    SummaryCardView(title: "Total Spent This Month", value: formattedTotalSpent)

                    if let mostExpensive = viewModel.mostExpensiveTransaction() {
                        let formattedMostExpensive = String(format: "£%.2f", mostExpensive.totalPrice)
                        SummaryCardView(title: "Most Expensive Transaction", value: "\(mostExpensive.companyName) - \(formattedMostExpensive)")
                    } else {
                        Text("No expensive transaction available")
                            .font(.subheadline) // Reduced font size for consistency
                            .padding()
                    }
                }
                .navigationBarTitle("Category Spending", displayMode: .inline)
                .padding(.horizontal) // Adjusted padding for the entire view
                .onAppear {
                    viewModel.fetchTransactionsForDateRange()
                }
            }
            .background(Color(UIColor.systemGroupedBackground)) // System background for adaptability
        }
    }
}

struct SummaryCardView: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { // Reduced spacing for a tighter layout
            Text(title)
                .font(.subheadline) // Smaller font size for high-fidelity
            Text(value)
                .font(.subheadline) // Consistent smaller font size
                .lineLimit(nil)

        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemFill)) // Subtle background color
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1) // More subtle shadow
    }
}
        
        struct DateNavigationView: View {
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
            
            func dateRangeText(for viewModel: TransactionViewModel) -> String {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: viewModel.startDate) + " - " + formatter.string(from: viewModel.endDate)
            }
            
            struct NavigationButton: View {
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
        
        struct SpendingChartView: View {
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
    
    
    struct CategoryWiseSpendingView_Previews: PreviewProvider {
        static var previews: some View {
            CategoryWiseSpendingView(viewModel: TransactionViewModel())
        }
    }
