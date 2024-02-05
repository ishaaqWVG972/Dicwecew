

import SwiftUI
import Charts

struct RecentSpendingTimeView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @State private var showingMonthYearPicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    HeaderTitle(title: "Spending Overview")
                    TimeFramePickerView(viewModel: viewModel, showingMonthYearPicker: $showingMonthYearPicker)

                    if viewModel.filteredTransactions.isEmpty {
                        Text("No data available for this period")
                            .padding()
                    } else {
                        ChartView(viewModel: viewModel)
                        CategoryGridView(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("Recent Spending")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.fetchTransactionsFromDB()
            }
            .sheet(isPresented: $showingMonthYearPicker) {
                MonthYearPicker(selectedMonth: $viewModel.currentMonth, selectedYear: $viewModel.currentYear) {
                    viewModel.updateForSpecificMonthAndYear(month: viewModel.currentMonth, year: viewModel.currentYear)
                }
            }
        }
    }

    private struct HeaderTitle: View {
        let title: String

        var body: some View {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top)
        }
    }


    private struct ChartView: View {
        @ObservedObject var viewModel: TransactionViewModel

        var body: some View {
            VStack {
                TotalSpendingView(viewModel: viewModel) // Corrected this line
                Chart {
                    ForEach(viewModel.filteredTransactions.sorted(by: { $0.totalPrice < $1.totalPrice }), id: \.id) { transaction in
                        BarMark(
                            x: .value("Category", transaction.categoryName ?? ""),
                            y: .value("Amount", transaction.totalPrice)
                        )
                        .foregroundStyle(by: .value("Category", transaction.categoryName ?? ""))
                    }
                }
                .frame(height: 250)
                .padding()
            }
        }
    }

    private struct TotalSpendingView: View { // Corrected 'View'
        @ObservedObject var viewModel: TransactionViewModel

        var body: some View {
            let totalSpending = viewModel.filteredTransactions.reduce(0) { $0 + $1.totalPrice }
            return Text("Total Spending: £\(totalSpending, specifier: "%.2f")")
                .font(.title2)
                .padding(.bottom)
        }
    }



    private struct CategoryGridView: View {
        @ObservedObject var viewModel: TransactionViewModel

        var body: some View {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 15)], spacing: 15) {
                ForEach(viewModel.getAggregatedSpendingByCategory(), id: \.id) { categorySpending in
                    CategorySpendingBox(category: categorySpending.category, amount: categorySpending.amount)
                }
            }
            .padding()
        }
    }
}

struct TimeFramePickerView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @Binding var showingMonthYearPicker: Bool

    var body: some View {
        Picker("Select Timeframe", selection: $viewModel.selectedTimeFrame) {
            Text("This Week").tag(TimeFrame.thisWeek)
            Text("Last Week").tag(TimeFrame.lastWeek)
            Text("This Month").tag(TimeFrame.thisMonth)
            Text("Last Month").tag(TimeFrame.lastMonth)
            Text("All Time").tag(TimeFrame.allTime)
            Text("Select Month/Year").tag(TimeFrame.specificMonth(0, 0))
            
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: viewModel.selectedTimeFrame) { newValue in
            if case .specificMonth = newValue {
                showingMonthYearPicker = true
            } else {
                viewModel.updateTransactionsForSelectedTimeFrame()
            }
        }
    }
}

struct CategorySpendingBox: View {
    let category: String
    let amount: Double
    
    var body: some View {
        VStack {
            HStack {
                Text(category)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "£%.2f", amount))
                    .font(.subheadline)
            }
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .shadow(radius: 3)
        }
        .padding(.horizontal)
    }
}

struct RecentSpendingTimeView_Previews: PreviewProvider {
    static var previews: some View {
        RecentSpendingTimeView(viewModel: TransactionViewModel())
    }
}
