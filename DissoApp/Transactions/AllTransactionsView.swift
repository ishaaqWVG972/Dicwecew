import SwiftUI

struct AllTransactionsView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @State private var selectedTimeFrame: TimeFrame = .thisMonth
    @State private var showingTimeFrameMenu = false
    @State private var showingCategoryList = false
    @State private var showingManualTransactionView = false

    var body: some View {
        List {
            Section(header: TimeFramePicker(selectedTimeFrame: $selectedTimeFrame, action: setFilter)) {
                ForEach(viewModel.filteredTransactions) { transaction in
                    TransactionCard(transaction: transaction)
                }
                .onDelete(perform: viewModel.deleteTransaction)
            }
        }
        
        
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Transactions")
        .toolbar {
            Button("Manage Categories") {
                showingCategoryList = true
            }
        }
        .sheet(isPresented: $showingCategoryList) {
            CategoryListView()
        }
    }

    private func setFilter(to timeFrame: TimeFrame) {
        selectedTimeFrame = timeFrame
        viewModel.filterTransactions(by: timeFrame)
    }
}

struct TimeFramePicker: View {
    @Binding var selectedTimeFrame: TimeFrame
    let action: (TimeFrame) -> Void

    var body: some View {
        Picker("Filter", selection: $selectedTimeFrame) {
            Text("Last Week").tag(TimeFrame.lastWeek)
            Text("Last Month").tag(TimeFrame.lastMonth)
            Text("This Month").tag(TimeFrame.thisMonth)
            Text("All Time").tag(TimeFrame.allTime) 
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedTimeFrame, perform: action)
    }
}

struct AllTransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        AllTransactionsView(viewModel: TransactionViewModel())
    }
}



//import SwiftUI
//
//struct AllTransactionsView: View {
//    @ObservedObject var viewModel: TransactionViewModel
//    @State private var selectedTimeFrame: TimeFrame = .thisMonth
//    @State private var showingManualTransactionView = false
//    @State private var showingCategoryList = false
//
//    var body: some View {
//        VStack {
//            HStack {
//                Button(action: {
//                    showingManualTransactionView = true
//                }) {
//                    Text("Add Transaction")
//                        .foregroundColor(.blue)
//                }
//
//                Spacer()
//
//                Button(action: {
//                    showingCategoryList = true
//                }) {
//                    Text("Manage Categories")
//                        .foregroundColor(.blue)
//                }
//            }
//            .padding()
//
//            List {
//                Section(header: TimeFramePicker(selectedTimeFrame: $selectedTimeFrame, action: setFilter)) {
//                    ForEach(viewModel.filteredTransactions) { transaction in
//                        TransactionCard(transaction: transaction)
//                    }
//                    .onDelete(perform: viewModel.deleteTransaction)
//                }
//            }
//            .listStyle(InsetGroupedListStyle())
//        }
//        .navigationTitle("Transactions")
//        .sheet(isPresented: $showingManualTransactionView) {
//            ManualTransactionView(viewModel: viewModel)
//        }
//        .sheet(isPresented: $showingCategoryList) {
//            CategoryListView()
//        }
//    }
//
//    private func setFilter(to timeFrame: TimeFrame) {
//        selectedTimeFrame = timeFrame
//        viewModel.filterTransactions(by: timeFrame)
//    }
//}
//
//struct TimeFramePicker: View {
//    @Binding var selectedTimeFrame: TimeFrame
//    let action: (TimeFrame) -> Void
//
//    var body: some View {
//        Picker("Filter", selection: $selectedTimeFrame) {
//            Text("Last Week").tag(TimeFrame.lastWeek)
//            Text("Last Month").tag(TimeFrame.lastMonth)
//            Text("This Month").tag(TimeFrame.thisMonth)
//            Text("All Time").tag(TimeFrame.allTime)
//        }
//        .pickerStyle(SegmentedPickerStyle())
//        .onChange(of: selectedTimeFrame, perform: action)
//    }
//}
//
//struct AllTransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        AllTransactionsView(viewModel: TransactionViewModel())
//    }
//}
