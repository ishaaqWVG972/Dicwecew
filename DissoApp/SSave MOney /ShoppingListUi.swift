import SwiftUI

struct ShoppingListUI: View {
    @State private var shoppingItems: [String] = []
    @State private var newItemName: String = ""
    @State private var showingDetails = false
    @State private var recommendedStore: String = ""
    @State private var showError: Bool = false
    @ObservedObject var viewModel: TransactionViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("Shopping List")
                        .font(.largeTitle)
                        .padding()

                    HStack {
                        TextField("Add item...", text: $newItemName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: addItem) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()

                    LazyVStack {
                        ForEach(shoppingItems, id: \.self) { item in
                            HStack {
                                Text(item)
                                    .padding()
                                Spacer()
                            }
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                        }
                        .onDelete(perform: deleteItem)
                    }

                    Button("Get Cheapest Store") {
                        calculateCheapestStore()
                    }
                    .buttonStyle(ActionButtonStyle())

                    if !recommendedStore.isEmpty {
                        recommendationView
                    }
                }
            }
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var recommendationView: some View {
          VStack {
              Text("We recommend \(recommendedStore) for the lowest total cost.")
                  .padding()
                  .background(Color.blue)
                  .foregroundColor(.white)
                  .cornerRadius(5)
              
              Button("Details") {
                  showingDetails = true
              }
              .padding()
              .background(Color.purple)
              .foregroundColor(.white)
              .cornerRadius(5)
          }
          .padding(.bottom, 50) // Add padding at the bottom to ensure content is not cut off
      }
    
    private func addItem() {
        guard !newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        shoppingItems.append(newItemName)
        newItemName = ""
    }
    
    private func calculateCheapestStore() {
         guard let userId = KeychainManager.shared.getUserId() else {
             print("Error: User ID not found.")
             showError = true
             return
         }

         viewModel.calculateCheapestStore(for: shoppingItems, userId: userId) { result in
             switch result {
             case .success(let store):
                 self.recommendedStore = store
             case .failure(let error):
                 print("Error calculating the cheapest store: \(error.localizedDescription)")
                 self.showError = true
             }
         }
     }


    
    private func deleteItem(at offsets: IndexSet) {
        shoppingItems.remove(atOffsets: offsets)
    }

}

struct ActionButtonStyle: ButtonStyle {
    var backgroundColor: Color = .green
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .padding(.horizontal)
    }
}

struct CheapestOptionsDetailView: View {
    var shoppingItems: [String]
    @State private var detailedOptions: [String: (store: String, price: Double)] = [:]
    @State private var recommendedStore: String = ""
    @State private var totalCost: Double = 0.0

    var body: some View {
        List {
            Section(header: Text("Cheapest Options")) {
                ForEach(shoppingItems, id: \.self) { item in
                    if let details = detailedOptions[item] {
                        HStack {
                            Text(item)
                            Spacer()
                            Text(details.store)
                            Text("£\(details.price, specifier: "%.2f")")
                                .frame(width: 80, alignment: .trailing)
                        }
                    }
                }
            }
            
            Section(header: Text("Recommended Store")) {
                HStack {
                    Text(recommendedStore)
                    Spacer()
                    Text("Total: £\(totalCost, specifier: "%.2f")")
                }
            }
        }
        .onAppear(perform: fetchDetails)
    }

    // Inside CheapestOptionsDetailView

    private func fetchDetails() {
          do {
              // Fetching the detailed cheapest options for each item
              detailedOptions = try DatabaseManager.shared.fetchDetailedCheapestOptions(for: shoppingItems)
              
              // Compute the total cost for each store and find the recommended store
              var storeCosts = [String: Double]()
              for (_, (store, price)) in detailedOptions {
                  storeCosts[store, default: 0.0] += price
              }
              
              // Determine the cheapest store by finding the one with the lowest total cost
              if let cheapest = storeCosts.min(by: { $0.value < $1.value }) {
                  recommendedStore = cheapest.key
                  totalCost = cheapest.value
              } else {
                  // Handle the case where no store is found or no products are available
                  recommendedStore = "Not found"
                  totalCost = 0.0
              }
          } catch {
              // Handle any errors that occur during fetching
              print("An error occurred while fetching the cheapest options: \(error.localizedDescription)")
              // You may want to update the UI to inform the user of the error
          }
      }
  }



