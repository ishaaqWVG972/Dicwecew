import SwiftUI
import VisionKit
import Vision
import UIKit

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
    @State private var isShowingImagePickerView = false
    
    @State private var showMatchConfirmation = false
    @State private var suggestedProductName: String = ""
    @State private var allowCustomProductNameEntry = false
    @State private var showCustomNameDialog = false

    @State private var showCustomProductNameEntry = false
    @State private var customProductName = ""
    @State private var showingCustomProductNameEntryView = false

    @State private var showingProductSuggestions = false
    @State private var suggestedProductNames: [String] = []

    
    @State private var selectedImage: UIImage? // This should be set to the image picked by the user

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

                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .disabled(isDateLocked)

                    Button("Start Scanning") {
                        isScanning = true
                    }
                    .sheet(isPresented: $isScanning) {
                        // Ensure ScanDocumentView is correctly implemented
                    }

                    Button("Add Product") {
                        if let priceDouble = Double(price), !productName.isEmpty {
                            let suggestionResult = viewModel.suggestProductMatch(for: productName)
                            suggestedProductNames = suggestionResult.suggestedNames

                            print("Suggestion Result: \(suggestionResult.matchFound), Names: \(suggestedProductNames)")

                            if suggestionResult.matchFound {
                                showingProductSuggestions = true
                            } else {
                                // Directly add the product or show custom name entry if needed
                                confirmAndAddProduct(productName: productName, price: priceDouble)
                            }
                        } else {
                            print("Invalid input")
                        }
                    }



                }
                
                Section(header: Text("Current Products")) {
                    ForEach(currentProducts, id: \.id) { product in
                        HStack {
                            Text(product.name)
                            Spacer()
                            Text("£\(product.price, specifier: "%.2f")")
                        }
                    }
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
                
                // This is the new section with the button to present UploadImageView
                Section {
                    NavigationLink(destination: TextView(viewModel: viewModel)) {
                                       Text("Upload or Take Image")
                                   }
                               }
                
                if selectedImage != nil {
                                   // Display the selected image (optional)
                                   Section(header: Text("Selected Image")) {
                                       Image(uiImage: selectedImage!)
                                           .resizable()
                                           .scaledToFit()
                                   }
                               }
                
            }
            .navigationBarTitle("Add Transaction", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Categories") {
                        showingCategorySelection = true
                    }
                }
            }
            .sheet(isPresented: $showingCategorySelection) {
                CategorySelectionView(selectedCategoryId: $selectedCategoryId, onCategorySelected: { categoryName in
                    selectedCategoryName = categoryName
                    showingCategorySelection = false // Close the sheet
                })
            }
            .alert(isPresented: $showMatchConfirmation) { // User confirmation dialog for product match
                Alert(
                    title: Text("Confirm Product Name"),
                    message: Text("Did you mean '\(suggestedProductName)'?"),
                    primaryButton: .default(Text("Yes")) {
                        // User confirms the match
                        confirmAndAddProduct(productName: suggestedProductName, price: Double(price) ?? 0.0)
                    },
                    secondaryButton: .default(Text("No")) {
                        // User rejects the match; show custom product name entry dialog
                        customProductName = "" // Reset custom product name
                        showingCustomProductNameEntryView = true
                    }
                )
            }
            .sheet(isPresented: $showingCustomProductNameEntryView) {
                CustomProductNameEntryView(customProductName: $customProductName) {
                    // Add the product with the custom name
                    if !customProductName.isEmpty {
                        confirmAndAddProduct(productName: customProductName, price: Double(price) ?? 0.0)
                        customProductName = "" // Reset for next use
                        showingCustomProductNameEntryView = false // Dismiss the sheet
                    }
                }
            }
            
            .sheet(isPresented: $showingProductSuggestions) {
                ProductSuggestionsView(suggestedNames: $suggestedProductNames, viewModel: viewModel) { selectedName in
                    confirmAndAddProduct(productName: selectedName, price: Double(price) ?? 0.0)
                    showingProductSuggestions = false
                }
            }




            .onAppear {
                // Load products from FormView into currentProducts and lock the date
                loadProductsAndLockDate()
            }
        }
    }

    
    private func loadProductsAndLockDate() {
         if !viewModel.productEntries.isEmpty {
             // Convert ProductEntry to Product if necessary, or directly use if they're the same
             currentProducts = viewModel.productEntries.map { Product(id: UUID(), name: $0.name, price: Double($0.price) ?? 0.0) }
             // Update and lock the date with the one selected in FormView
             selectedDate = viewModel.selectedDate
             isDateLocked = true // Lock the date picker to prevent changes
         }
     }

    


//     func addProduct() {
//        if let priceDouble = Double(price), !productName.isEmpty {
//            let newProduct = Product(id: UUID(), name: productName, price: priceDouble)
//            currentProducts.append(newProduct)
//            
//            viewModel.handleNewProductInput(for: productName)
//            
//            productName = ""
//            price = ""
//            isDateLocked = true
//        } else {
//            print("Invalid input")
//        }
//    }
    
    func addProduct() {
        if let priceDouble = Double(price), !productName.isEmpty {
            // First, check for a suggested product match
            let suggestionResult = viewModel.suggestProductMatch(for: productName)

            suggestedProductNames = suggestionResult.suggestedNames
            
            if suggestionResult.matchFound {
                // Matches found, present the suggestions for the user to confirm or enter a custom name
                showingProductSuggestions = true
            } else {
                // No matches found, directly allow entry of a custom name.
                // Here, you could either automatically add the product or ask the user to confirm the new product name.
                confirmAndAddProduct(productName: productName, price: priceDouble)
            }
        } else {
            print("Invalid input")
        }
        
        do {
            let mappings = try DatabaseManager.shared.fetchAllMappings()
            for mapping in mappings {
                print("Canonical: \(mapping.canonical), Variation: \(mapping.variation)")
            }
        } catch {
            print("Failed to fetch mappings: \(error)")
        }

    }

    
    func confirmAndAddProduct(productName: String, price: Double) {
        let newProduct = Product(id: UUID(), name: productName, price: price)
        currentProducts.append(newProduct)
        // Clear the input fields
        self.productName = ""
        self.price = ""
        isDateLocked = true
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
        let pattern = "\\b\\d+\\.\\d{2}\\b" // Matches price format e.g., "10.99"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           let range = Range(match.range, in: text) {
            return Double(text[range])
        }
        return nil
    }
    
    func extractProducts(from recognizedText: String) -> [Product] {
        // Split the recognized text into lines
        let lines = recognizedText.split(separator: "\n")
        var products: [Product] = []

        // Define a regular expression for price extraction
        let priceRegex = try! NSRegularExpression(pattern: "\\b\\d+\\.\\d{2}\\b", options: [])

        for line in lines {
            let currentLine = String(line)
            // Attempt to find a price in the line
            let range = NSRange(location: 0, length: currentLine.utf16.count)
            if let match = priceRegex.firstMatch(in: currentLine, options: [], range: range),
               let priceRange = Range(match.range, in: currentLine) {
                // Extract the price and product name
                let priceString = currentLine[priceRange]
                if let price = Double(priceString) {
                    // Assume everything before the price is the product name
                    let productName = currentLine[..<priceRange.lowerBound].trimmingCharacters(in: .whitespaces)
                    products.append(Product(id: UUID(), name: productName, price: price))
                }
            }
        }
        
        return products
    }

    
    func matchItemsWithPrices(itemObservations: [VNRecognizedTextObservation], priceObservations: [VNRecognizedTextObservation], imageHeight: CGFloat) -> [Product] {
        var products: [Product] = []

        // Filter observations based on their vertical position to ignore header/footer
        let filteredItemObservations = itemObservations.filter { $0.boundingBox.midY > 0.2 && $0.boundingBox.midY < 0.8 }
        let filteredPriceObservations = priceObservations.filter { $0.boundingBox.midY > 0.2 && $0.boundingBox.midY < 0.8 }

        // Iterate over item observations to find the closest price to the right
        for itemObs in filteredItemObservations {
            let itemName = itemObs.topCandidates(1).first?.string ?? ""
            
            // Convert item bounding box Y to image coordinates
            let itemY = imageHeight * (1 - itemObs.boundingBox.minY - itemObs.boundingBox.height / 2)
            
            // Find the closest price observation based on vertical alignment and to the right of the item name
            if let matchedPrice = filteredPriceObservations.min(by: { (a, b) -> Bool in
                // Convert price bounding box Y to image coordinates for comparison
                let priceAY = imageHeight * (1 - a.boundingBox.minY - a.boundingBox.height / 2)
                let priceBY = imageHeight * (1 - b.boundingBox.minY - b.boundingBox.height / 2)
                
                let distanceA = abs(priceAY - itemY) + (a.boundingBox.minX < itemObs.boundingBox.minX ? 10000 : 0) // Penalize prices to the left
                let distanceB = abs(priceBY - itemY) + (b.boundingBox.minX < itemObs.boundingBox.minX ? 10000 : 0)
                
                return distanceA < distanceB
            }) {
                let priceString = matchedPrice.topCandidates(1).first?.string.filter("0123456789.".contains) ?? ""
                if let price = Double(priceString) {
                    products.append(Product(id: UUID(), name: productName, price: price))
                }
            }
        }

        return products
    }
    
}

struct CustomProductNameEntryView: View {
    @Binding var customProductName: String
    var onAdd: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter Custom Product Name", text: $customProductName)
                    .padding()
                Button("Add") {
                    onAdd()
                }
                .padding()
                .disabled(customProductName.isEmpty)
            }
            .navigationBarTitle("Custom Product Name", displayMode: .inline)
        }
    }
}

struct ProductSuggestionsView: View {
    @Binding var suggestedNames: [String]
    @ObservedObject var viewModel: TransactionViewModel
    @Environment(\.presentationMode) var presentationMode
    var onConfirm: (String) -> Void

    @State private var customName: String = ""

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Suggested Names")) {
                    // Iterate over suggested names and create a button for each
                    ForEach(suggestedNames, id: \.self) { name in
                        Button(action: {
                            // When a suggested name is clicked, handle user confirmation
                            viewModel.handleUserConfirmation(for: name, withSuggestedCanonicalName: name, isExactMatch: true)
                            onConfirm(name)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text(name)
                        }
                    }
                }

                Section(header: Text("Custom Name")) {
                    TextField("Enter custom name", text: $customName)
                    Button("Confirm Custom Name") {
                        if !customName.isEmpty {
                            // When confirming a custom name, handle it appropriately
                            viewModel.handleUserConfirmation(for: customName, withSuggestedCanonicalName: nil, isExactMatch: false)
                            onConfirm(customName)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .disabled(customName.isEmpty)
                }
            }
            .navigationBarTitle("Select Product Name", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}




struct ManualTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        ManualTransactionView(viewModel: TransactionViewModel())
    }
}
