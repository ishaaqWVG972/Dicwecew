import SwiftUI
struct BrowseView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @Binding var isUserLoggedIn: Bool

    var body: some View {
        List {
            NavigationLink("Budget", destination: BudgetUi(viewModel: viewModel))
            NavigationLink("Shopping List", destination: ShoppingListUI(viewModel: viewModel))
            NavigationLink("Stats", destination: StatsUi(viewModel: viewModel))
//            NavigationLink("Account", destination: AccountView(isUserLoggedIn: $isUserLoggedIn, viewModel: viewModel))
            NavigationLink("Saving Opportunities", destination: SavingsOpportunitiesView(viewModel: viewModel))
         NavigationLink("Product Impact", destination: ProductImpactView(viewModel: viewModel))
        }
        .navigationTitle("Browse")
    }
}

struct BrowseView_Previews: PreviewProvider {
    static var previews: some View {
        BrowseView(viewModel: TransactionViewModel(), isUserLoggedIn: .constant(true))
        
    }
}
