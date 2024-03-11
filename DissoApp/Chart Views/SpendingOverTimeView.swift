import SwiftUI
import Charts

struct SpendingOverTimeView: View {
    @ObservedObject var viewModel: TransactionViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) { // Increased spacing for better whitespace
                Text("Spending Over Time")
                    .font(.system(size: 34, weight: .bold, design: .rounded)) // Modern, rounded font
                    .padding(.top, 20)

                if !viewModel.spendingOverTime().isEmpty {
                    spendingChart
                } else {
                    Text("No spending data available")
                        .font(.title2)
                        .foregroundColor(.gray)
                }

                summaryCards

                budgetVsActualSpending
            }
            .padding(.horizontal) // Adjusted padding for better alignment
        }
        .navigationTitle("Spending Trends")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var spendingChart: some View {
        Chart(viewModel.spendingOverTime()) { spending in
            LineMark(
                x: .value("Date", spending.date),
                y: .value("Amount", spending.amount)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 3))
            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .leading, endPoint: .trailing))
            PointMark(
                x: .value("Date", spending.date),
                y: .value("Amount", spending.amount)
            )
            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .top, endPoint: .bottom))
            .symbolSize(10)
        }
        .frame(height: 300)
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 20)], spacing: 20) { // Use a grid for a modern layout
            SpendingSummaryCardView(
                title: "Month-to-Month",
                value: viewModel.monthToMonthComparison(),
                icon: "arrow.triangle.2.circlepath.circle.fill" // Example icon
            )

            SpendingSummaryCardView(
                title: "High & Low Months",
                value: viewModel.highestAndLowestSpendingMonth(),
                icon: "chart.bar.fill" // Example icon
            )

            SpendingSummaryCardView(
                title: "Average Monthly",
                value: viewModel.averageMonthlySpending(),
                icon: "calendar" // Example icon
            )

            SpendingSummaryCardView(
                title: "Top Categories",
                value: viewModel.topTransactionCategory(), // Ensure correct method
                icon: "tag.fill" // Example icon
            )
        }
        .padding(.top) // Added padding for better spacing
    }

    private var budgetVsActualSpending: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Budget vs. Actual Spending")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.vertical, 8)

            ForEach(viewModel.calculateBudgetVsActual(), id: \.category) { comparison in
                VStack(alignment: .leading, spacing: 6) {
                    Text(comparison.category)
                        .font(.headline)
                        .foregroundColor(Color.blue)
                    HStack {
                        Text("Budgeted: £\(comparison.budgeted, specifier: "%.2f")")
                        Spacer()
                        Text("Actual: £\(comparison.actual, specifier: "%.2f")")
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 2)
            }
        }
    }
}

struct SpendingSummaryCardView: View {
    var title: String
    var value: String
    var icon: String // Added an icon for a richer UI

    var body: some View {
        HStack(spacing: 16) { // Horizontal layout for a compact card
            Image(systemName: icon)
                .foregroundColor(.blue)
                .imageScale(.large)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.primary)
                Text(value)
                    .font(.subheadline) // Smaller font for the value
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2) // Softened shadow
        .padding(.horizontal)
    }
}

struct SpendingOverTimeView_Previews: PreviewProvider {
    static var previews: some View {
        SpendingOverTimeView(viewModel: TransactionViewModel())
    }
}
