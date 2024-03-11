import SwiftUI
import Charts

struct StatsUi: View {
    @StateObject var viewModel = TransactionViewModel()  // Data source

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) { // Optimized spacing for clarity
                    StatsSummaryView(viewModel: viewModel)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.systemBackground)) // Neutral background
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)

                    VStack(spacing: 16) {
                        ChartLink(destination: CategoryWiseSpendingView(viewModel: viewModel), title: "Category-Wise Spending")
                        ChartLink(destination: SpendingOverTimeView(viewModel: viewModel), title: "Spending Over Time")
                        ChartLink(destination: RecentSpendingTimeView(viewModel: viewModel), title: "Recent Spending")
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ChartLink<Destination: View>: View {
    var destination: Destination
    var title: String

    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground)) // Subtle background
            .cornerRadius(8)
            .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle()) // Ensure native button behavior
    }
}

struct StatsSummaryView: View {
    @ObservedObject var viewModel: TransactionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top Categories")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(viewModel.topExpenseCategories(), id: \.category) { item in
                HStack {
                    Text(item.category)
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("£\(item.amount, specifier: "%.2f")")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground)) // Light and neutral
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct StatsUi_Previews: PreviewProvider {
    static var previews: some View {
        StatsUi()
    }
}
