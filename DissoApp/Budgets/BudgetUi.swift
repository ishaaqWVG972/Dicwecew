import SwiftUI

struct BudgetUi: View {
    @ObservedObject var viewModel: TransactionViewModel
    @State private var showingBudgetCreation = false

    var body: some View {
        NavigationView {
            VStack {
                BudgetTimeFramePicker(selectedTimeFrame: $viewModel.selectedBudgetTimeFrame)
                    .onChange(of: viewModel.selectedBudgetTimeFrame) { _ in
                        viewModel.filterBudgetsForSelectedTimeFrame()
                    }
                    .padding()

                List {
                    // New Section for Total Budget
                    // Within the BudgetUi struct
                    Section(header: Text("Total Budget")) {
                        if viewModel.budget.categories["Total"] != nil {
                            TotalBudgetView(viewModel: viewModel)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        viewModel.deleteTotalBudget()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }


                    // Existing Sections for Category Budgets
                    Section {
                        ForEach(viewModel.budgetsList, id: \.category) { budgetItem in
                            BudgetCard(
                                title: budgetItem.category,
                                spentPercentage: viewModel.calculateSpentPercentage(for: budgetItem.category),
                                remainingBudget: viewModel.calculateRemainingBudget(for: budgetItem.category),
                                remainingDaystext: viewModel.remainingDaysForBudget(category: budgetItem.category))
                        }
                        .onDelete(perform: viewModel.deleteBudget)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Budgets")
            .navigationBarItems(trailing: Button(action: {
                showingBudgetCreation.toggle()
            }) {
                Image(systemName: "plus").imageScale(.large).padding()
            })
            .sheet(isPresented: $showingBudgetCreation) {
                BudgetCreationOverlay(showModal: $showingBudgetCreation, viewModel: viewModel)
            }
            .onAppear() {
                viewModel.loadBudgets()
                viewModel.initializeBudgetsAndSpending()
            }
        }
    }
}

struct BudgetCard: View {
    var title: String
    var spentPercentage: Double
    var remainingBudget: Double
    var remainingDaystext : String

    var body: some View {
           VStack(alignment: .leading) {
               Text(title)
                   .font(.headline)
               ProgressBar(value: spentPercentage, maxValue: 1)
                   .frame(height: 20)
                   .cornerRadius(10)
               HStack {
                   Text("Remaining Amount:")
                   Spacer()
                   Text(String(format: "%.2f", remainingBudget))
                       .bold()
               }
               Text(remainingDaystext)
                   .font(.caption)
                   .foregroundColor(.gray)
           }
           .padding()
           .background(Color(.secondarySystemBackground))
           .cornerRadius(12)
           .shadow(radius: 2)
       }
}

struct BudgetTimeFramePicker: View {
    @Binding var selectedTimeFrame: BudgetTimeFrame

    var body: some View {
        Picker("Select Time Frame", selection: $selectedTimeFrame) {
            Text("Week").tag(BudgetTimeFrame.week)
            Text("Month").tag(BudgetTimeFrame.month)
            Text("All Budgets").tag(BudgetTimeFrame.total)
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}
struct ProgressBar: View {
    var value: Double
    var maxValue: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.systemTeal))
                
                Rectangle().frame(width: min(CGFloat(self.value)/CGFloat(self.maxValue) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(Color(UIColor.systemBlue))
                    .animation(.linear, value: value)
            }.cornerRadius(45.0)
        }
    }
}

struct TotalBudgetView: View {
    @ObservedObject var viewModel: TransactionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let totalBudgetDetail = viewModel.budget.categories["Total"] {
                VStack(alignment: .leading) {
                    Text("Total Budget").font(.headline)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Budget: £\(totalBudgetDetail.limit, specifier: "%.2f")")
                            Text("Days left: \(viewModel.remainingDays)")
                            Text("Remaining: £\(viewModel.totalBudgetRemaining, specifier: "%.2f")")
                        }
                        Spacer()
                        ProgressBar(value: viewModel.totalBudgetSpentPercentage, maxValue: 1)
                            .frame(height: 20)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
        }
    }
}


struct ClosestBudgetCategoryView: View {
    @ObservedObject var viewModel: TransactionViewModel

    var body: some View {
        if let closestCategory = viewModel.closestCategoryToLimit() {
            VStack(alignment: .leading) {
                Text("\(closestCategory.category) Budget").font(.headline)
                HStack {
                    VStack(alignment: .leading) {
                        Text("Budget: £\(closestCategory.limit, specifier: "%.2f")")
                        Text("Days left: \(closestCategory.remainingDays)")
                        Text("Remaining: £\(closestCategory.remaining, specifier: "%.2f")")
                    }
                    Spacer()
                    ProgressBar(value: closestCategory.spentPercentage, maxValue: 1)
                        .frame(height: 20)
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
    }
}







struct BudgetUi_Previews: PreviewProvider {
    static var previews: some View {
        BudgetUi(viewModel: TransactionViewModel())
    }
}
