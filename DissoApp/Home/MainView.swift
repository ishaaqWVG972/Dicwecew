import SwiftUI

struct MainView: View {
    @Binding var isUserLoggedIn: Bool
    @ObservedObject var viewModel: TransactionViewModel

    @State private var showingManualTransactionView = false
    @State private var selectedTab: Int = 0
    
    @State private var showingHelpView = false


    var body: some View {
        NavigationView {
            VStack {
                // Content based on the selected tab
                switch selectedTab {
                case 0:
                    // Home tab content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) { // Increased spacing
                            Text("Welcome to Expense Explorer")
                                .font(.title2) // Slightly smaller font for better fit
                                .fontWeight(.bold)
                                .padding(.vertical, 2) // Reduced padding

                            Text("Track and manage your expenses efficiently and discover saving opportunities.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 5)

                            TotalBudgetView(viewModel: viewModel)
                            
                            ClosestBudgetCategoryView(viewModel: viewModel)
                                .padding(.vertical, 5) // Adjusted padding

                            SavingOpportunitiesTeaserView(viewModel: viewModel)
                                .padding(.vertical, 5) // Adjusted padding

                            // Category Cards
                            let spendingComparisons = viewModel.spendingComparisonByAllCategories()
                            ForEach(spendingComparisons.keys.sorted(), id: \.self) { category in
                                if let comparison = spendingComparisons[category] {
                                    CategoryCardView(category: category, lastMonthSpending: comparison.lastMonth, thisMonthSpending: comparison.thisMonth)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                case 1:
                    AllTransactionsView(viewModel: viewModel)
                case 2:
                    BrowseView(viewModel: viewModel, isUserLoggedIn: $isUserLoggedIn)
                case 3:
                    AccountView(isUserLoggedIn: $isUserLoggedIn, viewModel: viewModel)
                default:
                    Text("Additional Content")
                }

                Spacer() // Pushes the content and tabs to the top and bottom respectively
            }
            .navigationBarTitle("Expense Explorer", displayMode: .inline)
//            .navigationBarItems(leading: addButton)
            .navigationBarItems(leading: addButton, trailing: infoButton) // Add the help button here
                    
        }
        .sheet(isPresented: $showingManualTransactionView) {
            ManualTransactionView(viewModel: viewModel)
        }
        
        .sheet(isPresented: $showingHelpView) {
                    HelpView()
                }
        .onAppear {
            viewModel.fetchTransactionsFromDB()
            viewModel.loadBudgets()
        }
        // Improved Tab bar overlay
        .overlay(
            TabBarOverlay(selectedTab: $selectedTab),
            alignment: .bottom
        )
    }

    private var addButton: some View {
        Button(action: {
            showingManualTransactionView = true
            viewModel.resetTransactionDetails()
        }) {
            Image(systemName: "plus")
                .foregroundColor(.blue)
                .imageScale(.large)
        }
    }
    
    private var infoButton: some View{
        Button(action: {
            showingHelpView = true
        }) {
            Image(systemName: "info")
                .foregroundColor(.blue)
                .imageScale(.large)
        }
    }
}

struct HelpView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Welcome")) {
                    VStack(alignment: .leading) {
                        Text("Budgeting App for University Students")
                            .font(.headline)
                            .padding(.bottom, 2)
                        
                        Text("Designed to simplify budgeting and managing expenses, making financial management intuitive and effective for university students.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical)
                    .listRowBackground(Color(UIColor.systemGroupedBackground))
                }
                
                featureSection
                
                savingOpportunitiesSection
                
                dataTrendsSection
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("How to Use")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        // Dismiss action
                    }
                }
            }
        }
    }
    
    private var featureSection: some View {
        Section(header: Text("Features")) {
            FeatureItemView(iconName: "doc.text.viewfinder", title: "Receipt Uploads", description: "Automatically fill in transactions by uploading receipts and copying and pasting your products and prices.")
            
            FeatureItemView(iconName: "square.and.pencil", title: "Manual Entry", description: "Enter your own products and prices directly.")
            
            FeatureItemView(iconName: "rectangle.grid.1x2.fill", title: "Categorization", description: "Customizable categories for transaction organization.")
            
            FeatureItemView(iconName: "chart.pie.fill", title: "Budget Creation", description: "Manage finances with total and category-specific budgets.")
            
            FeatureItemView(iconName: "cart.fill", title: "Add Transactions on-the-go", description: "Easily add transactions while shopping, making it seamless to track expenses in real-time.")
            
            FeatureItemView(iconName: "antenna.radiowaves.left.and.right", title: "Offline Usage", description: "Use the app anywhere, even without an internet connection, for utmost convenience.")
        }
    }

    // Additional Sections if needed based on your request can be similarly structured.
    // Ensure the sections for Saving Opportunities and Data & Trends are also updated to match this high-fidelity approach.

    
    private var savingOpportunitiesSection: some View {
        Section(header: Text("Saving Opportunities")) {
            FeatureItemView(iconName: "tag.fill", title: "Discover Savings", description: "Find where you can save on items across different stores.")
        }
    }
    
    private var dataTrendsSection: some View {
        Section(header: Text("Data & Trends")) {
            FeatureItemView(iconName: "waveform.path.ecg", title: "Spending Insights", description: "Breakdown of transactions for better understanding.")
            
            FeatureItemView(iconName: "arrow.triangle.2.circlepath", title: "Month-to-Month Comparison", description: "View trends and compare spending across months.")
        }
    }
}

struct FeatureItemView: View {
    let iconName: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: iconName)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
                .padding(.top, 4)
            
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.bold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical)
    }
}




struct TabBarOverlay: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack {
            TabBarButton(iconName: "house.fill", label: "Home", isSelected: selectedTab == 0) { selectedTab = 0 }
            TabBarButton(iconName: "tray.full.fill", label: "Transactions", isSelected: selectedTab == 1) { selectedTab = 1 }
            TabBarButton(iconName: "magnifyingglass", label: "Browse", isSelected: selectedTab == 2) { selectedTab = 2 }
            TabBarButton(iconName: "person.fill", label: "Account", isSelected: selectedTab == 3) { selectedTab = 3 }
        }
        .padding(.vertical, 8)
        .background(BlurBackground())
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .animation(.easeInOut)
    }
}

struct BlurBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct TabBarButton: View {
    let iconName: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: iconName)
                    .foregroundColor(isSelected ? .blue : .gray)
                Text(label)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct SavingOpportunitiesTeaserView: View {
    @ObservedObject var viewModel: TransactionViewModel
    var body: some View {
        NavigationLink(destination: SavingsOpportunitiesView(viewModel: viewModel)) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Discover Saving Opportunities")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Get insights on how to save more based on your spending habits.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("See More")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .shadow(radius: 5)
        }
    }
}
