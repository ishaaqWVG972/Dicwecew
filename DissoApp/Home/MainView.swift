//import SwiftUI
//
//struct MainView: View {
//    @Binding var isUserLoggedIn: Bool
//    @ObservedObject var viewModel: TransactionViewModel
//   
//    @State private var showingManualTransactionView = false
//    @State private var selectedTab: Int = 0
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                // Content based on the selected tab
//                switch selectedTab {
//                case 0:
//                    Text("Welcome to Expense Explorer")
//                case 1:
//                    AllTransactionsView(viewModel: viewModel)
//                case 2:
//                    BrowseView(viewModel: viewModel)
//                default:
//                    Text("Home View Content")
//                }
//                
//                Spacer() // Pushes the content to the top
//                TotalBudgetView(viewModel: viewModel)
//               
//            }
//            
//            
//            
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Add transaction") {
//                        showingManualTransactionView = true
//                    }
//                }
//            }
//        }
//        .sheet(isPresented: $showingManualTransactionView) {
//            ManualTransactionView(viewModel: viewModel)
//        }
//        .onAppear {
//            if KeychainManager.shared.isLoggedIn() {
//                viewModel.fetchTransactionsFromDB()
//            }
//        }
//        // Tab bar
//        .overlay(
//            GeometryReader { geometry in
//                VStack {
//                    Spacer()
//                    HStack {
//                        Button(action: { self.selectedTab = 0 }) {
//                            Image(systemName: "house.fill")
//                                .accentColor(selectedTab == 0 ? .blue : .gray)
//                        }
//                        .frame(width: geometry.size.width / 3)
//                        
//                        Button(action: { self.selectedTab = 1 }) {
//                            Image(systemName: "list.bullet")
//                                .accentColor(selectedTab == 1 ? .blue : .gray)
//                        }
//                        .frame(width: geometry.size.width / 3)
//                        
//                        Button(action: { self.selectedTab = 2 }) {
//                            Image(systemName: "magnifyingglass")
//                                .accentColor(selectedTab == 2 ? .blue : .gray)
//                        }
//                        .frame(width: geometry.size.width / 3)
//                    }
//                    .frame(width: geometry.size.width, height: 100) // Adjust height as needed
//                    .background(Color(UIColor.systemBackground))
//                }
//            }
//            .edgesIgnoringSafeArea(.bottom), // Ensures tab bar stays at the bottom below safe area
//            alignment: .bottom
//        )
//    }
//}
//
//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        // Create a new instance of TransactionViewModel for the preview
//        let viewModel = TransactionViewModel()
//        // Pass this instance to MainView
//        MainView(isUserLoggedIn: .constant(true), viewModel: viewModel)
//    }
//}




//import SwiftUI
//
//struct MainView: View {
//    @Binding var isUserLoggedIn: Bool
//    @StateObject private var viewModel = TransactionViewModel()
//    @State private var showingManualTransactionView = false
//    @State private var selectedTab = 0
//    
//    init(isUserLoggedIn: Binding<Bool>) {
//        _isUserLoggedIn = isUserLoggedIn
//        // Set a custom background color for the TabView
//        UITabBar.appearance().barTintColor = UIColor(named: "PrimaryColor")
//        UITabBar.appearance().tintColor = UIColor.blue
//    }
//
//    var body: some View {
//        NavigationView {
//            TabView {
//                // Home tab
//                VStack {
////                    Image("ExpenseExplorerLogo") // Add your app logo
////                        .resizable()
////                        .aspectRatio(contentMode: .fit)
////                        .frame(width: 100, height: 100)
//                    Text("Welcome to Expense Explorer")
//                        .font(.title)
//                        .foregroundColor(.primary)
//                        .padding(.top, 16)
//                    Text("Track your expenses effortlessly.")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                        .padding(.top, 8)
//                    Spacer()
//                }
//                .tabItem {
//                    Label("Home", systemImage: "house.fill")
//                }
//                
//                // Transactions tab
//                AllTransactionsView(viewModel: viewModel)
//                    .tabItem {
//                        Label("Transactions", systemImage: "list.bullet")
//                    }
//                
//                // Stats tab
//                StatsUi(viewModel: viewModel)
//                    .tabItem {
//                        Label("Stats", systemImage: "chart.bar.fill")
//                    }
//                
//                // Account tab
//                AccountView(isUserLoggedIn: $isUserLoggedIn, viewModel: viewModel)
//                    .tabItem {
//                        Label("Account", systemImage: "person.fill")
//                    }
//                
//                // Shopping List tab
//                ShoppingListUI(viewModel: viewModel)
//                    .tabItem {
//                        Label("Shopping List", systemImage: "cart.fill")
//                    }
//                BudgetUi(viewModel: viewModel)
//                    .tabItem {
//                        Label("Budget", systemImage: "banknote.fill")
//                    }
//                
//            }
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Add transaction"){
//                        showingManualTransactionView = true
//                    }
//                }
//            }
//        }
//        
//        .sheet(isPresented: $showingManualTransactionView) {
//            ManualTransactionView(viewModel: viewModel)
//        }
//        .onAppear {
//            if KeychainManager.shared.isLoggedIn() {
//                viewModel.fetchTransactionsFromDB()
//            }
//        }
//    }
//}
//
//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainView(isUserLoggedIn: .constant(true))
//    }
//}



import SwiftUI

struct MainView: View {
    @Binding var isUserLoggedIn: Bool
    @ObservedObject var viewModel: TransactionViewModel
   
    @State private var showingManualTransactionView = false
    @State private var selectedTab: Int = 0

    var body: some View {
        NavigationView {
            VStack {
                // Content based on the selected tab
                switch selectedTab {
                case 0:
                    // Home tab content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome to Expense Explorer")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Description of app etc")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TotalBudgetView(viewModel: viewModel)
                    }
                    .padding()
                case 1:
                    AllTransactionsView(viewModel: viewModel)
                case 2:
                    BrowseView(viewModel: viewModel)
                default:
                    Text("Additional View Content")
                }
                
                Spacer() // Pushes the content and tabs to the top and bottom respectively
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Add transaction") {
                        showingManualTransactionView = true
                    }
                }
            }
            
        }
        .sheet(isPresented: $showingManualTransactionView) {
            ManualTransactionView(viewModel: viewModel)
        }
        .onAppear {
            if KeychainManager.shared.isLoggedIn() {
                viewModel.fetchTransactionsFromDB()
                viewModel.loadBudgets() // This should trigger a state update in the view model
            }
        }
        // Tab bar
        .overlay(
            TabBarOverlay(selectedTab: $selectedTab)
            ,alignment: .bottom
        )
        
    }
    
}

struct TabBarOverlay: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack {
                    TabBarButton(iconName: "house.fill", isSelected: selectedTab == 0) { selectedTab = 0 }
                    TabBarButton(iconName: "list.bullet", isSelected: selectedTab == 1) { selectedTab = 1 }
                    TabBarButton(iconName: "magnifyingglass", isSelected: selectedTab == 2) { selectedTab = 2 }
                }
                .frame(width: geometry.size.width, height: 50) // Adjust the height as needed for your tab bar
                .background(Color(UIColor.systemBackground))
            }
        }
    }
}

struct TabBarButton: View {
    let iconName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .accentColor(isSelected ? .blue : .gray)
                .frame(maxWidth: .infinity)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a new instance of TransactionViewModel for the preview
        let viewModel = TransactionViewModel()
        
        // Pass this instance to MainView
        MainView(isUserLoggedIn: .constant(true), viewModel: viewModel)
    }
}

