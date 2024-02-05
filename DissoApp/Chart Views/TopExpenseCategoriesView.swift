//
//
//
//import SwiftUI
//import Charts
//
//struct TopExpenseCategoriesView: View {
//    @ObservedObject var viewModel: TransactionViewModel
//
//    var body: some View {
//        VStack {
//            Text("Top Expense Categories")
//                .font(.title)
//                .padding()
//
//            Chart(viewModel.topExpenseCategories()) { spending in
//                BarMark(
//                    x: .value("Amount", spending.amount),
//                    y: .value("Category", spending.category)
//                )
//            }
//            .frame(height: 300)
//            .padding()
//        }
//        .navigationTitle("Top Expenses")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}
//
//struct TopExpenseCategoriesView_Previews: PreviewProvider {
//    static var previews: some View {
//        TopExpenseCategoriesView(viewModel: TransactionViewModel())
//    }
//}
