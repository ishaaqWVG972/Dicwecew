import SwiftUI

struct TransactionDetailView: View {
    var transaction: Transaction

    var body: some View {
        List {
            Section(header: Text("Details")) {
                HStack {
                    Text("Company")
                    Spacer()
                    Text(transaction.companyName)
                }
                
                HStack {
                    Text("Date")
                    Spacer()
                    Text(transaction.userSelectedDate)
                }
                
                if let categoryName = transaction.categoryName {
                    HStack {
                        Text("Category")
                        Spacer()
                        Text(categoryName)
                    }
                }
            }
            
            Section(header: Text("Products")) {
                ForEach(transaction.products) { product in
                    HStack {
                        Text(product.name)
                        Spacer()
                        Text(String(format: "£%.2f", product.price))
                    }
                }
            }
        }
        .navigationBarTitle("Transaction Details", displayMode: .inline)
    }
}

struct TransactionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionDetailView(transaction: Transaction(
            id: UUID(),
            companyName: "Sample Company",
            products: [Product(id: UUID(), name: "Product 1", price: 1.99)],
            userSelectedDate: "01-01-2023"
        ))
    }
}
