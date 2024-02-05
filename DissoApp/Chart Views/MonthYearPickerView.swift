import SwiftUI

struct MonthYearPicker: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    var onConfirm: () -> Void

    @Environment(\.presentationMode) var presentationMode

    let months = Calendar.current.monthSymbols
    let years: [Int] = Array(2000...Calendar.current.component(.year, from: Date()))

    var body: some View {
        NavigationView {
            Form {
                Picker("Month", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(self.months[month - 1]).tag(month)
                    }
                }

                Picker("Year", selection: $selectedYear) {
                    ForEach(years, id: \.self) { year in
                        Text("\(year)").tag(year)
                    }
                }

                Button("Confirm") {
                    onConfirm()
                    presentationMode.wrappedValue.dismiss()  // Dismiss the view
                }
            }
            .navigationBarTitle("Select Month/Year", displayMode: .inline)
        }
    }
}
