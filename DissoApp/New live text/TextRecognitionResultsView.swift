//import SwiftUI
//
//struct TextRecognitionResultsView: View {
//    @Binding var categorizedText: CategorizedText
//    @ObservedObject var viewModel: TransactionViewModel
//
//    var body: some View {
//        NavigationView {
//            Form {
//                Section(header: Text("Company Name")) {
//                    ForEach(Array($categorizedText.companyNames.enumerated()), id: \.offset) { index, _ in
//                        TextField("Company Name", text: $categorizedText.companyNames[index])
//                    }
//                }
//                
//                Section(header: Text("Products & Prices")) {
//                    ForEach(Array($categorizedText.productNames.enumerated()), id: \.offset) { index, _ in
//                        HStack {
//                            TextField("Product Name", text: $categorizedText.productNames[index])
//                            Spacer()
//                            TextField("Price", text: Binding<String>(
//                                get: { self.categorizedText.prices.indices.contains(index) ? self.categorizedText.prices[index] : "" },
//                                set: { newValue in
//                                    if self.categorizedText.prices.indices.contains(index) {
//                                        self.categorizedText.prices[index] = newValue
//                                    }
//                                }
//                            ))
//                        }
//                    }
//                }
//            }
//            .navigationBarTitle("Edit Recognized Text", displayMode: .inline)
//        }
//    }
//}




import SwiftUI

struct TextRecognitionResultsView: View {
    @State private var pastedText: String = ""
    @Binding var categorizedText: CategorizedText
    @ObservedObject var viewModel: TransactionViewModel

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pasted Text")) {
                    TextEditor(text: $pastedText)
                        .frame(height: 200)
                        .onAppear {
                            // Automatically paste text from the clipboard when the view appears
                            self.pastedText = UIPasteboard.general.string ?? ""
                        }
                }
                
                Section(header: Text("Company Name")) {
                    ForEach(Array($categorizedText.companyNames.enumerated()), id: \.offset) { index, _ in
                        TextField("Company Name", text: $categorizedText.companyNames[index])
                    }
                    if categorizedText.companyNames.isEmpty {
                        Button("Add Company Name") {
                            categorizedText.companyNames.append("")
                        }
                    }
                }
                
                Section(header: Text("Products & Prices")) {
                    ForEach(Array($categorizedText.productNames.enumerated()), id: \.offset) { index, _ in
                        HStack {
                            TextField("Product Name", text: $categorizedText.productNames[index])
                            Spacer()
                            TextField("Price", text: Binding<String>(
                                get: { self.categorizedText.prices.indices.contains(index) ? self.categorizedText.prices[index] : "" },
                                set: { newValue in
                                    if self.categorizedText.prices.indices.contains(index) {
                                        self.categorizedText.prices[index] = newValue
                                    }
                                }
                            ))
                        }
                    }
                    Button("Add Product & Price") {
                        categorizedText.productNames.append("")
                        categorizedText.prices.append("")
                    }
                }
            }
            .navigationBarTitle("Edit Recognized Text", displayMode: .inline)
            .navigationBarItems(trailing: Button("Process") {
                // Here you could add logic to process the manually entered data or split the pastedText
                // For example, if you have a method in your viewModel to categorize pasted text:
                // viewModel.categorizePastedText(pastedText)
            })
        }
        .onAppear {
            // This is a simple approach to fill in the pasted text.
            // You might want to implement more sophisticated text parsing and categorization logic
            self.pastedText = UIPasteboard.general.string ?? ""
        }
    }
}


