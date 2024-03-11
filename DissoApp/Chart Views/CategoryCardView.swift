import SwiftUI
import Charts

struct CategoryCardView: View {
    var category: String
    var lastMonthSpending: Double
    var thisMonthSpending: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(category)
                .font(.title2)
                .fontWeight(.semibold)
            
            chartView
            
            Text(spendingDifferenceText)
                .font(.body)
        }
        .padding()
        .background(Color(.systemBackground)) // Adapting to dark mode
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var chartView: some View {
        Chart {
            BarMark(
                x: .value("Month", "Last Month"),
                y: .value("Spending", lastMonthSpending)
            )
            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .top, endPoint: .bottom))
            .cornerRadius(5)
            
            BarMark(
                x: .value("Month", "This Month"),
                y: .value("Spending", thisMonthSpending)
            )
            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.green, .yellow]), startPoint: .top, endPoint: .bottom))
            .cornerRadius(5)
        }
        .chartYScale(domain: 0...max(lastMonthSpending, thisMonthSpending, 1) * 1.1) // Add a 10% buffer to the top for aesthetics
        .frame(height: 200)
        .padding(.horizontal, -10) // Adjust padding as necessary to align with your UI design
    }

    var spendingDifferenceText: String {
        let difference = thisMonthSpending - lastMonthSpending
        let formattedDifference = String(format: "%.2f", abs(difference))
        if difference > 0 {
            return "This month you spent £\(formattedDifference) more on \(category) than last month."
        } else if difference < 0 {
            return "This month you spent £\(formattedDifference) less on \(category) than last month."
        } else {
            return "Spending on \(category) is the same as last month."
        }
    }
}
