


import SwiftUI
import Charts

struct SpendingOverTimeView: View {
    @ObservedObject var viewModel: TransactionViewModel

    var body: some View {
        VStack {
            Text("Spending Over Time")
                .font(.title)
                .padding()

            Chart(viewModel.spendingOverTime()) { spending in
                LineMark(
                    x: .value("Date", spending.date),
                    y: .value("Amount", spending.amount)
                )
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 300)
            .padding()
        }
        .navigationTitle("Spending Trends")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SpendingOverTimeView_Previews: PreviewProvider {
    static var previews: some View {
        SpendingOverTimeView(viewModel: TransactionViewModel())
    }
}
