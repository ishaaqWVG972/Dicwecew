
import SwiftUI
import VisionKit
import Vision

struct ManualTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: TransactionViewModel
    @State private var currentProducts: [Product] = []
    @State private var productName: String = ""
    @State private var price: String = ""
    @State private var companyName: String = ""
    @State private var selectedDate = Date()
    @State private var isScanning = false
    @State private var recognizedText = ""
    @State private var isDateLocked = false
    
    @State private var selectedCategoryId: Int64?
    @State private var showingCategorySelection = false
    @State private var selectedCategoryName: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Company Name")) {
                    TextField("Company Name", text: $companyName)
                }

                Section(header: Text("Product Details")) {
                    TextField("Product Name", text: $productName)
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                    

                    Section(header: Text("Transaction Date")) {
                        DatePicker("Select Date", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                            .disabled(isDateLocked)
                            .padding()
                            .datePickerStyle(GraphicalDatePickerStyle())
                    }

                    Button("Start Scanning") {
                        isScanning = true
                    }
                    .sheet(isPresented: $isScanning) {
                        ScanDocumentView(recognizedText: $recognizedText)
                            .onDisappear {
                                processScannedText()
                            }
                    }

                    Button("Add Product") {
                        addProduct()
                    }
                }
                
                Section(header: Text("Current Products")) {
                                  ForEach(currentProducts, id: \.id) { product in
                                      HStack {
                                          Text(product.name)
                                              .frame(maxWidth: .infinity, alignment: .leading)
                                          Text("£\(product.price, specifier: "%.2f")")
                                              .frame(alignment: .trailing)
                                              
                                      }
                                  }
//                                   Uncomment if you want to enable deletion of products
                                   .onDelete(perform: deleteProduct)
                              }

                if let categoryName = selectedCategoryName {
                                  Section {
                                      HStack {
                                          Text("Selected Category:")
                                          Spacer()
                                          Text(categoryName)
                                              .foregroundColor(.gray)
                                      }
                                  }
                              }

                Button("Submit Transaction") {
                    submitTransaction()
                }
            }
            .navigationBarTitle("Add Transaction", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCategorySelection = true
                    }) {
                        Text("Categories")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCategorySelection) {
                   CategorySelectionView(selectedCategoryId: $selectedCategoryId, onCategorySelected: { categoryName in
                       selectedCategoryName = categoryName
                       showingCategorySelection = false // Close the sheet
                   })
        }
    }

    private func addProduct() {
        if let priceDouble = Double(price), !productName.isEmpty {
            let newProduct = Product(id: UUID(), name: productName, price: priceDouble)
            currentProducts.append(newProduct)
            productName = ""
            price = ""
            isDateLocked = true
        } else {
            print("Invalid input")
        }
    }

    private func submitTransaction() {
        let formattedDate = formatDate(selectedDate)
        let newTransaction = Transaction(
            id: UUID(),
            companyName: companyName,
            products: currentProducts,
            userSelectedDate: formattedDate,
            categoryId: selectedCategoryId
        )

        viewModel.addTransaction(newTransaction)
        companyName = ""
        currentProducts.removeAll()
        presentationMode.wrappedValue.dismiss()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }

    private func deleteProduct(at offsets: IndexSet) {
        currentProducts.remove(atOffsets: offsets)
    }

    private func processScannedText() {
        let lines = recognizedText.split(separator: "\n")
        if let firstLine = lines.first {
            companyName = String(firstLine)
        }

        var productNames = [String]()
        var prices = [Double]()

        for line in lines.dropFirst() {
            if let price = extractPrice(String(line)) {
                prices.append(price)
            } else {
                productNames.append(String(line))
            }
        }

        for (productName, price) in zip(productNames, prices) {
            currentProducts.append(Product(id: UUID(), name: productName, price: price))
        }
    }

    private func extractPrice(_ text: String) -> Double? {
        let pattern = "\\d+\\.\\d{2}"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           let range = Range(match.range, in: text),
           let price = Double(text[range]) {
            return price
        }
        return nil
    }
}

struct ManualTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        ManualTransactionView(viewModel: TransactionViewModel())
    }
}
