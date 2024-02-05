import SwiftUI

struct TransactionCard: View {
    var transaction: Transaction

    var body: some View {
        NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.companyName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Date: \(transaction.userSelectedDate)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "£%.2f", transaction.totalPrice))
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Tap for details")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 1)
        }
        .buttonStyle(PlainButtonStyle())  // To remove the default button styling of NavigationLink
        .accessibilityElement(children: .combine)
    }
}


struct TransactionCard_Previews: PreviewProvider {
    static var previews: some View {
        TransactionCard(transaction: Transaction(
            id: UUID(),
            companyName: "Sample Company",
            products: [Product(id: UUID(), name: "Product 1", price: 1.99)],
            userSelectedDate: "01-01-2023" // Example date in String format
        ))
    }
}
