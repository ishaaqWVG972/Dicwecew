import SwiftUI
import NaturalLanguage

// Extension to help with regex matching
extension String {
    func matchesRegex(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }

    func extractPrice() -> String {
        // Adjust this method to fit the price format you're working with
        return self.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: ".")
    }
}


// Struct for holding product entry details
struct ProductEntry: Identifiable {
    let id: UUID = UUID()
    var name: String = ""
    var price: String = ""
}

// Struct for parsed receipt items
struct ReceiptItem {
    var name: String
    var price: String
}

// FormView with added functionality for parsing and filling product details
struct FormView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var companyName: String = ""
    @State private var receiptText: String = ""
    @State private var productEntries: [ProductEntry] = [ProductEntry()] // Start with one empty entry
    @State private var selectedDate: Date = Date() // Add this line for date selection
    @ObservedObject var viewModel: TransactionViewModel

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Paste Receipt Text Here")) {
                    TextEditor(text: $receiptText)
                        .frame(height: 200)
                        .border(Color.gray, width: 1)
                        .padding()
                }
                
                Section(header: Text("Company Information")) {
                    TextField("Enter Company Name", text: $companyName)
                }
                
                // Date picker section
                Section(header: Text("Transaction Date")) {
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                }
                
                ForEach($productEntries.indices, id: \.self) { index in
                    Section(header: Text("Product Details #\(index + 1)")) {
                        HStack {
                            TextField("Product Name", text: $productEntries[index].name)
                            TextField("Price", text: $productEntries[index].price)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                
                Button(action: {
                    // Trigger parsing and filling of the form
                    parseAndFill(receiptText)
                }) {
                    Text("Fill In Form")
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    // Add another product entry
                    productEntries.append(ProductEntry())
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Another Product")
                    }
                }
                
                Button("Submit") {
                    // Directly assign the new date to the view model's selectedDate property
                    viewModel.selectedDate = selectedDate
                    viewModel.productEntries = productEntries
                    presentationMode.wrappedValue.dismiss()
                }

            }
            .navigationBarTitle("Details Form", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: EditButton())
        }
    }
    
    // Function to parse the pasted text and fill the form
    private func parseAndFill(_ text: String) {
        productEntries.removeAll() // Clear existing entries

        print("Parsing text: \(text)") // Debug statement to confirm function is called and text is received

        let items = parseReceiptText(text) // Parse the text

        for item in items {
            let productEntry = ProductEntry(name: item.name, price: item.price)
            productEntries.append(productEntry)
        }

        print("Parsed items: \(items)") // Debug statement to confirm items are parsed
    }
    
    func parseReceiptText(_ text: String) -> [ReceiptItem] {
        let lines = text.components(separatedBy: "\n")

        // Use the detectMixedFormat function to determine the receipt format
        if detectMixedFormat(lines: lines) {
            return parseMixedFormat(lines: lines)
        } else {
            return parseSequentialFormat(lines: lines)
        }
    }
    

    func detectMixedFormat(lines: [String]) -> Bool {
        var previousLineIsPrice = false
        for line in lines {
            let currentLineIsPrice = line.matchesRegex("\\d+\\.\\d{2}\\s*[A-Z]?")
            // If the current line's format (price or not) is different from the previous line,
            // and this pattern repeats, it's likely a mixed format.
            if currentLineIsPrice != previousLineIsPrice {
                previousLineIsPrice = currentLineIsPrice
            } else {
                // Found two consecutive lines of the same type (both prices or both products),
                // suggesting it's not a mixed format.
                return false
            }
        }
        return true
    }

    func parseMixedFormat(lines: [String]) -> [ReceiptItem] {
        var items: [ReceiptItem] = []
        var currentItem: String?

        for line in lines {
            if line.matchesRegex("\\d+\\.\\d{2}\\s*[A-Z]?") {
                if let productName = currentItem {
                    items.append(ReceiptItem(name: productName, price: line.extractPrice()))
                    currentItem = nil // Reset for the next item
                }
            } else {
                currentItem = line
            }
        }

        return items
    }
    
    func parseSequentialFormat(lines: [String]) -> [ReceiptItem] {
        let productLines = lines.filter { !$0.matchesRegex("\\d+\\.\\d{2}\\s*[A-Z]?") }
        let priceLines = lines.filter { $0.matchesRegex("\\d+\\.\\d{2}\\s*[A-Z]?") }.map { $0.extractPrice() }

        var items: [ReceiptItem] = []
        for (index, product) in productLines.enumerated() {
            if index < priceLines.count {
                let price = priceLines[index]
                items.append(ReceiptItem(name: product, price: price))
            }
        }

        return items
    }
}
