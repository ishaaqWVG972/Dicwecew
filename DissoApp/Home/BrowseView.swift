import SwiftUI
struct BrowseView: View {
    @ObservedObject var viewModel: TransactionViewModel

    var body: some View {
        List {
            NavigationLink("Budget", destination: BudgetUi(viewModel: viewModel))
            NavigationLink("Shopping List", destination: ShoppingListUI(viewModel: viewModel))
            NavigationLink("Stats", destination: StatsUi(viewModel: viewModel))
            NavigationLink("Account", destination: AccountView(isUserLoggedIn: .constant(true), viewModel: viewModel))
        }
        .navigationTitle("Browse")
    }
}

struct BrowseView_Previews: PreviewProvider {
    static var previews: some View {
        BrowseView(viewModel: TransactionViewModel())
    }
}
