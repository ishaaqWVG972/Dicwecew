

import SwiftUI
import Charts

struct StatsUi: View {
    @StateObject var viewModel = TransactionViewModel()  // Data source

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    // Summary view for top category
                    SummaryView(viewModel: viewModel)

                    // Charts section
                    VStack(spacing: 20) {
                        ChartLink(destination: CategoryWiseSpendingView(viewModel: viewModel), title: "Category-Wise Spending")
//                        ChartLink(destination: TopExpenseCategoriesView(viewModel: viewModel), title: "Top Expense Categories")
                        ChartLink(destination: SpendingOverTimeView(viewModel: viewModel), title: "Spending Over Time")
                        ChartLink(destination: RecentSpendingTimeView(viewModel: viewModel), title: "Recent Spending")
                    }
                }
                .padding()
            }
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
            ChartPreview(title: title)
                .padding(.horizontal)
        }
    }
}

struct ChartPreview: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(10)
            .overlay(
                Text("Tap for details")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    .padding(6),
                alignment: .bottomTrailing
            )
    }
}
