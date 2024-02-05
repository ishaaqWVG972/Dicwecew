
import Foundation


enum TimeFrame: Hashable {
    case lastWeek, lastMonth, thisMonth, thisWeek, specificMonth(Int, Int), allTime // month, year
}
    
extension Calendar {
    func isDate(_ date: Date, inLastWeekOf referenceDate: Date) -> Bool {
        guard let weekAgo = self.date(byAdding: .weekOfYear, value: -1, to: referenceDate) else { return false }
        return date >= weekAgo && date <= referenceDate
    }

    func isDate(_ date: Date, inLastMonthOf referenceDate: Date) -> Bool {
        guard let monthAgo = self.date(byAdding: .month, value: -1, to: referenceDate) else { return false }
        return date >= monthAgo && date <= referenceDate
    }

    func isDate(_ date: Date, inCurrentMonthOf referenceDate: Date) -> Bool {
        let components = self.dateComponents([.year, .month], from: referenceDate)
        guard let startOfMonth = self.date(from: components) else { return false }
        return date >= startOfMonth && date <= referenceDate
    }
}

class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var filteredTransactions: [Transaction] = []
    
    @Published var currentMonth: Int
    @Published var currentYear: Int
    
    @Published var startDate : Date
    @Published var endDate : Date
    @Published var selectedTimeFrame: TimeFrame = .thisMonth
    
    @Published var budget: Budget = Budget(total: 0, categories: [:], spent: [:])
    @Published var totalSpending: Double = 0
    @Published var selectedBudgetTimeFrame: BudgetTimeFrame = .total
    @Published var totalBudgetRemaining: Double = 0
    @Published var totalBudgetSpentPercentage: Double = 0
    @Published var totalSpent: Double = 0
    @Published var totalBudget: Double = 100 // Represents the total budget amount set for the time frame
    @Published var totalBudgetUsed: Double = 0
    

    init() {
        
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month], from: now)
        currentMonth = components.month ?? Calendar.current.component(.month, from: Date())
        currentYear = components.year ?? Calendar.current.component(.year, from: Date())
        endDate = now
        startDate = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        fetchTransactionsForDateRange()
        
        
        // ... existing initialization code ...
    }
    
    func getAggregatedSpendingByCategory() -> [CategorySpending] {
        var categoryTotals = [String: Double]()
        for transaction in filteredTransactions {
            let categoryName = transaction.categoryName ?? "Unknown"
            categoryTotals[categoryName, default: 0] += transaction.totalPrice
        }
        return categoryTotals.map { CategorySpending(category: $0.key, amount: $0.value) }
    }
    
    
    func updateForSpecificMonthAndYear(month: Int, year: Int) {
        selectedTimeFrame = .specificMonth(month, year)
        currentMonth = month
        currentYear = year
        updateTransactionsForSelectedTimeFrame()
    }
    
    func moveToPreviousMonth() {
        guard let newEndDate = Calendar.current.date(byAdding: .month, value: -1, to: startDate) else {
            return
        }
        endDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
        startDate = newEndDate
        fetchTransactionsForDateRange()
    }
    
    func moveToNextMonth() {
        let currentDate = Date()
        guard endDate < currentDate else {
            // Already showing the current month, do not move further
            return
        }
        startDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? endDate
        endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        endDate = min(endDate, currentDate) // Ensure endDate does not go past current date
        fetchTransactionsForDateRange()
    }
    
    func canMoveToNextMonth() -> Bool {
        // Check if the endDate is less than the current date to enable the next month button
        return endDate < Date()
    }
    
    func fetchTransactionsForDateRange() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        filteredTransactions = transactions.filter { transaction in
            guard let transactionDate = dateFormatter.date(from: transaction.userSelectedDate) else {
                return false
            }
            return transactionDate >= startDate && transactionDate <= endDate
        }
    }
    
    func moveToDate(month: Int, year: Int) {
        currentMonth = month
        currentYear = year
        filterTransactionsForSpecificMonth(month: month, year: year)
    }
    
    
    
    
    private func currentDate() -> Date {
        var components = DateComponents()
        components.year = currentYear
        components.month = currentMonth
        return Calendar.current.date(from: components) ?? Date()
    }

    func fetchTransactionsFromDB() {
        guard let userId = KeychainManager.shared.getUserId() else {
            print("User not logged in or user ID not available")
            return
        }
        
        do {
            var fetchedTransactions = try DatabaseManager.shared.fetchAllTransactions(for: userId)
            for (index, transaction) in fetchedTransactions.enumerated() {
                if let categoryId = transaction.categoryId {
                    do {
                        let categoryName = try DatabaseManager.shared.fetchCategoryName(for: categoryId)
                        fetchedTransactions[index].categoryName = categoryName
                    } catch {
                        print("Error fetching category name: \(error)")
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.transactions = fetchedTransactions
                self.filteredTransactions = fetchedTransactions
            }
        } catch {
            print("Error fetching transactions: \(error)")
        }
    }
    
    
    func updateTotalSpent() {
          // Calculate the total spent from transactions
          self.totalSpent = calculateTotalSpending()
      }
    
    
    func addTransaction(_ transaction: Transaction) {
        guard KeychainManager.shared.isLoggedIn(),
              let userId = KeychainManager.shared.getUserId() else {
            print("User not logged in or user ID not available")
            return
        }
        
        do {
            try DatabaseManager.shared.addTransaction(
                companyName: transaction.companyName,
                totalPrice: transaction.totalPrice,
                userSelectedDate: transaction.userSelectedDate,
                products: transaction.products,
                userId: userId,
                categoryId: transaction.categoryId // Ensure this is passed correctly
            )
            fetchTransactionsFromDB()
        } catch {
            print("Error adding transaction: \(error)")
        }
//        WORKING VERSION !!! updateBudgetAfterTransactionChange()
        updateAfterTransactionChange()
    }
    
    
    func deleteTransaction(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        let transactionToDelete = transactions[index]
        
        // Delete transaction from the database
        do {
            try DatabaseManager.shared.deleteTransaction(transactionId: transactionToDelete.id)
            fetchTransactionsFromDB() // Fetch updated transactions
        } catch {
            print("Error deleting transaction: \(error)")
        }
        updateAfterTransactionChange()
    }
    
    func categoryWiseSpending() -> [CategorySpending] {
        // Calculate category wise spending for filteredTransactions
        var spendingDict = [String: Double]()
        for transaction in filteredTransactions {
            if let categoryName = transaction.categoryName {
                spendingDict[categoryName, default: 0] += transaction.totalPrice
            }
        }
        return spendingDict.map { CategorySpending(category: $0.key, amount: $0.value) }
    }
    
    func topExpenseCategories(limit: Int = 5) -> [CategorySpending]{
        let sorted = categoryWiseSpending().sorted {$0.amount > $1.amount}
        return Array(sorted.prefix(limit))
    }
    
    func spendingOverTime() -> [TimeSpending] {
        var spendingDict = [String: Double]()
        for transaction in transactions {
            spendingDict[transaction.userSelectedDate, default: 0] += transaction.totalPrice
        }
        return spendingDict.map {TimeSpending(date: $0.key, amount: $0.value)}
    }
    
    func fetchRecentTransactions() {
        let filtered = transactions.filter { transaction in
            guard let transactionDate = parseDate(transaction.userSelectedDate) else { return false }
            return Calendar.current.isDate(transactionDate, inLastWeekOf: Date())
        }
        DispatchQueue.main.async {
            self.filteredTransactions = filtered
        }
    }
    
    func fetchTransactionsForMonth(_ month: Int, year: Int) {
        let filtered = transactions.filter { transaction in
            guard let transactionDate = parseDate(transaction.userSelectedDate) else { return false }
            let components = Calendar.current.dateComponents([.year, .month], from: transactionDate)
            return components.year == year && components.month == month
        }
        DispatchQueue.main.async {
            self.filteredTransactions = filtered
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy" // Update the format to match your date string format
        return dateFormatter.date(from: dateString)
    }
    
    func categoryWiseSpendingLastMonth() -> [CategorySpending] {
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        return transactions
            .filter { transaction in
                guard let transactionDate = dateFormatter.date(from: transaction.userSelectedDate) else {
                    return false
                }
                return transactionDate >= oneMonthAgo && transactionDate <= Date()
            }
            .reduce(into: [String: Double]()) { dict, transaction in
                guard let categoryName = transaction.categoryName else { return }
                dict[categoryName, default: 0] += transaction.totalPrice
            }
            .map { CategorySpending(category: $0.key, amount: $0.value) }
    }
    
    
    func fetchTransactionsForSpecificMonth(month: Int, year: Int) {
        let filtered = transactions.filter { transaction in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy"
            guard let transactionDate = dateFormatter.date(from: transaction.userSelectedDate),
                  let transactionYear = Calendar.current.dateComponents([.year], from: transactionDate).year,
                  let transactionMonth = Calendar.current.dateComponents([.month], from: transactionDate).month else {
                return false
            }
            return transactionYear == year && transactionMonth == month
        }
        DispatchQueue.main.async {
            self.filteredTransactions = filtered
        }
    }
    
    func filterTransactions(by timeFrame: TimeFrame) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        let now = Date()
        let startOfCurrentMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now))!
        let startOfLastMonth = Calendar.current.date(byAdding: .month, value: -1, to: startOfCurrentMonth)!
        let startOfLastWeek = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        
        switch timeFrame {
        case .lastWeek:
            filteredTransactions = transactions.filter {
                guard let transactionDate = dateFormatter.date(from: $0.userSelectedDate) else { return false }
                return transactionDate >= startOfLastWeek && transactionDate <= now
            }
        case .lastMonth:
            filteredTransactions = transactions.filter {
                guard let transactionDate = dateFormatter.date(from: $0.userSelectedDate) else { return false }
                return transactionDate >= startOfLastMonth && transactionDate < startOfCurrentMonth
            }
        case .thisMonth:
            filteredTransactions = transactions.filter {
                guard let transactionDate = dateFormatter.date(from: $0.userSelectedDate) else { return false }
                return transactionDate >= startOfCurrentMonth && transactionDate <= now
            }
        case .thisWeek:
            let startOfThisWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            filteredTransactions = transactions.filter {
                guard let transactionDate = dateFormatter.date(from: $0.userSelectedDate) else { return false }
                return transactionDate >= startOfThisWeek && transactionDate <= now
            }
        case .specificMonth: break
            // Implement logic for specific month and year if required
            // ...
        case .allTime:
            filteredTransactions = transactions // No filtering needed for all time
        }
    }
    
    
    func filterTransactionsForSpecificMonth(month: Int, year: Int) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        filteredTransactions = transactions.filter { transaction in
            guard let transactionDate = dateFormatter.date(from: transaction.userSelectedDate),
                  let transactionYear = Calendar.current.dateComponents([.year], from: transactionDate).year,
                  let transactionMonth = Calendar.current.dateComponents([.month], from: transactionDate).month else {
                return false
            }
            return transactionYear == year && transactionMonth == month
        }
    }
    
    func nextTimeFrame(current: TimeFrame) -> TimeFrame {
        switch current {
        case .lastWeek:
            return .thisWeek
        case .thisWeek:
            return .lastMonth
        case .lastMonth:
            return .thisMonth
        case .thisMonth, .specificMonth:
            // Decide what should be the next timeframe after thisMonth or specificMonth
            return .lastWeek
        case.allTime:
            return .allTime
        }
    }
    
    
    // Function to get the previous time frame
    func previousTimeFrame(current: TimeFrame) -> TimeFrame {
        switch current {
        case .lastWeek:
            return .thisMonth
        case .thisWeek:
            return .lastWeek
        case .lastMonth:
            return .thisWeek
        case .thisMonth, .specificMonth:
            // Decide what should be the previous timeframe before thisMonth or specificMonth
            return .lastMonth
        case.allTime:
            return.allTime
        }
    }
    
    
    func dateRange(for timeFrame: TimeFrame) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM"
        
        let now = Date()
        let startOfCurrentMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now))!
        let startOfLastMonth = Calendar.current.date(byAdding: .month, value: -1, to: startOfCurrentMonth)!
        let startOfLastWeek = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        
        switch timeFrame {
        case .lastWeek:
            let endOfLastWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfLastWeek)!
            return "\(dateFormatter.string(from: startOfLastWeek)) to \(dateFormatter.string(from: endOfLastWeek))"
        case .lastMonth:
            let endOfLastMonth = Calendar.current.date(byAdding: .month, value: 1, to: startOfLastMonth)!
            return "\(dateFormatter.string(from: startOfLastMonth)) to \(dateFormatter.string(from: endOfLastMonth))"
        case .thisMonth:
            return "\(dateFormatter.string(from: startOfCurrentMonth)) to \(dateFormatter.string(from: now))"
        case .thisWeek:
            let startOfThisWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let endOfThisWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfThisWeek)!
            return "\(dateFormatter.string(from: startOfThisWeek)) to \(dateFormatter.string(from: endOfThisWeek))"
        case .specificMonth(let month, let year):
            // Handle specific month and year
            return "Specific Month: \(month), \(year)"
        case .allTime:
            return "All Time"
        }
    }
    
    
    func fetchCategories(completion: @escaping ([Category]) -> Void) {
        do {
            let categories = try DatabaseManager.shared.fetchCategories()
            completion(categories)
        } catch {
            print("Error fetching categories: \(error)")
            completion([])
        }
    }
    
    
    func setTotalBudget(_ amount: Double, startDate: Date, endDate: Date) {
            guard let userId = KeychainManager.shared.getUserId() else {
                print("User not logged in or user ID not available")
                return
            }
            
            do {
                try DatabaseManager.shared.setTotalBudget(userId: userId, limit: amount, startDate: startDate, endDate: endDate)
                // Update the total budget in the budget object
                let budgetDetails = BudgetDetails(limit: amount, timeFrame: .total, startDate: startDate, endDate: endDate)
                self.budget.categories["Total"] = budgetDetails
                print("Total budget set: \(amount)")
            } catch {
                print("Error setting total budget: \(error)")
            }
        }
        
        func setCategoryBudget(_ categoryName: String, amount: Double, timeFrame: BudgetTimeFrame, startDate: Date, endDate: Date) {
            guard let userId = KeychainManager.shared.getUserId() else {
                print("User not logged in or user ID not available")
                return
            }
            
            let budgetDetails = BudgetDetails(limit: amount, timeFrame: timeFrame, startDate: startDate, endDate: endDate)
            
            do {
                try DatabaseManager.shared.setCategoryBudget(userId: userId, category: categoryName, detail: budgetDetails)
                print("Budget set for \(categoryName): \(amount)")
            } catch {
                print("Error setting budget for category \(categoryName): \(error)")
            }
        }
        
    func loadBudgets() {
        guard let userId = KeychainManager.shared.getUserId() else {
            print("User not logged in or user ID not available")
            return
        }
        
        do {
            let userBudgets = try DatabaseManager.shared.fetchUserBudgets(userId: userId)
            DispatchQueue.main.async {
                self.budget.categories = userBudgets
                self.calculateRemainingTotalBudget()
                _ = self.calculateTotalBudgetSpentPercentage() // Call the function to update the spent percentage
                print("Budgets loaded successfully")
            }
        } catch {
            print("Error loading budgets: \(error)")
        }
    }

    
  
        
        func filterBudgetsForSelectedTimeFrame() {
            guard let userId = KeychainManager.shared.getUserId() else {
                print("User not logged in or user ID not available")
                return
            }

            do {
                // Fetch budgets only for the logged-in user
                let userBudgets = try DatabaseManager.shared.fetchUserBudgets(userId: userId)
                
                let currentDate = Date() // Assuming you want to compare against the current date
                let calendar = Calendar.current
                let currentYear = calendar.component(.year, from: currentDate)
                let currentMonth = calendar.component(.month, from: currentDate)

                switch selectedBudgetTimeFrame {
                case .week:
                    // Filter for week-specific budgets
                    budget.categories = userBudgets.filter { $0.value.timeFrame == selectedBudgetTimeFrame }
                case .month:
                    // Filter for month-specific budgets and include "total" budgets if their date range matches the current month.
                    budget.categories = userBudgets.filter { budgetDetail in
                        if budgetDetail.value.timeFrame == .month {
                            return true
                        } else if budgetDetail.value.timeFrame == .total {
                            let startMonth = calendar.component(.month, from: budgetDetail.value.startDate)
                            let startYear = calendar.component(.year, from: budgetDetail.value.startDate)
                            let endMonth = calendar.component(.month, from: budgetDetail.value.endDate)
                            let endYear = calendar.component(.year, from: budgetDetail.value.endDate)
                            // Check if the "total" budget's date range includes the current month and year.
                            return (startYear < currentYear || (startYear == currentYear && startMonth <= currentMonth)) &&
                                   (endYear > currentYear || (endYear == currentYear && endMonth >= currentMonth))
                        }
                        return false
                    }
                case .total:
                    // Since "Total" is not a user-selectable option anymore, adjust or remove this case as needed.
                    budget.categories = userBudgets
                }
            } catch {
                print("Error fetching budgets: \(error)")
            }
        }

            func calculateRemainingBudget(for category: String) -> Double {
                   let spentAmount = budget.spent[category] ?? 0
                   if let details = budget.categories[category] {
                       return max(0, details.limit - spentAmount)
                   }
                   return 0.0
               }
    
            func calculateSpentPercentage(for category: String) -> Double {
                let spentAmount = budget.spent[category] ?? 0
                if let details = budget.categories[category], details.limit > 0 {
                    return min(spentAmount / details.limit, 1.0)
                }
                return 0.0
            }
    
            // Update spent amounts based on transactions
            func updateSpentAmounts() {
                // Reset spent amounts
                budget.spent = [:]
                
                // Aggregate spending by category
                let aggregatedSpending = getAggregatedSpendingByCategory()
                for categorySpending in aggregatedSpending {
                    budget.spent[categorySpending.category] = categorySpending.amount
                }
                
                // Compare with budgets and update accordingly
                for (category, details) in budget.categories {
                    let spentAmount = budget.spent[category] ?? 0
                    let remaining = max(0, details.limit - spentAmount)
                    // Here, you can add logic to check if the budget time frame is valid
                }
            }
            
    
    func calculateRemainingTotalBudget() {
        let totalSpent = calculateTotalSpending()
        let totalBudgetLimit = budget.categories["Total"]?.limit ?? 0
        totalBudgetRemaining = max(0, totalBudgetLimit - totalSpent)
    }

    
//    func calculateTotalBudgetSpentPercentage() {
//        let totalSpent = calculateTotalSpending()
//        let totalBudgetLimit = budget.categories["Total"]?.limit ?? 0
//        totalBudgetSpentPercentage = totalBudgetLimit > 0 ? min(totalSpent / totalBudgetLimit, 1.0) : 0.0
//    }

    func calculateTotalBudgetSpentPercentage() -> Double {
        let totalSpent = calculateTotalSpending()
        let totalBudgetLimit = budget.categories["Total"]?.limit ?? 0
        totalBudgetSpentPercentage = totalBudgetLimit > 0 ? min(totalSpent / totalBudgetLimit, 1.0) : 0.0
        return totalBudgetSpentPercentage
    }


    func calculateTotalSpending() -> Double {
        // Assuming transactions is an array of Transaction objects
        let total = transactions.reduce(0) { $0 + $1.totalPrice }
        print("Calculated Total Spending: \(total)")
        return total
    }


    
            
//             Function to calculate the spent percentage for total budget
            func calculateTotalSpentPercentage() -> Double {
                guard budget.total > 0 else {
                    return 0.0
                }
                return min(totalSpending / budget.total, 1.0)
            }
            
            func initializeBudgetsAndSpending() {
                loadBudgets()
                updateSpentAmounts()
                calculateTotalSpending()
                calculateRemainingTotalBudget()
            }
            
            func remainingDaysForBudget(category: String) -> String {
                guard let budgetDetails = budget.categories[category] else {
                    return ""
                }
                
                let currentDate = Date()
                let remainingDays = Calendar.current.dateComponents([.day], from: currentDate, to: budgetDetails.endDate).day ?? 0
                
                return remainingDays > 0 ? "\(remainingDays) days remaining" : "Budget expired"
            }
            
    var budgetsList: [BudgetItem] {
        budget.categories.compactMap { category, details in
            if category != "Total" { // Exclude the "Total" budget from the category list
                return BudgetItem(category: category, details: details)
            } else {
                return nil
            }
        }
    }

            
            func deleteBudget(at offsets: IndexSet) {
                guard let userId = KeychainManager.shared.getUserId() else {
                    print("User not logged in or user ID not available")
                    return
                }
                offsets.forEach { index in
                    let categoryToDelete = budgetsList[index].category
                    // Call the database manager to delete the budget
                    do {
                        try DatabaseManager.shared.deleteBudget(userId: userId, category: categoryToDelete)
                        // Update local budgets
                        budget.categories.removeValue(forKey: categoryToDelete)
                        print("Budget for \(categoryToDelete) deleted successfully")
                    } catch {
                        print("Error deleting budget for category \(categoryToDelete): \(error)")
                    }
                }
            }
            
        
        func updateTransactionsForSelectedTimeFrame() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy" // Ensure this matches the format stored in `userSelectedDate`
            
            filteredTransactions = transactions.filter { transaction in
                guard let transactionDate = dateFormatter.date(from: transaction.userSelectedDate) else {
                    return false
                }
                switch selectedTimeFrame {
                case .thisWeek:
                    return Calendar.current.isDate(transactionDate, equalTo: Date(), toGranularity: .weekOfYear)
                case .thisMonth:
                    return Calendar.current.isDate(transactionDate, equalTo: Date(), toGranularity: .month)
                case .lastWeek:
                    let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
                    return transactionDate >= oneWeekAgo && transactionDate <= Date()
                case .lastMonth:
                    let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
                    return transactionDate >= oneMonthAgo && transactionDate <= Date()
                case .specificMonth(let month, let year):
                    let components = Calendar.current.dateComponents([.year, .month], from: transactionDate)
                    return components.month == month && components.year == year
                case .allTime:
                    return true
                }
            }
            
            // Once transactions are filtered, calculate the total spending.
            calculateTotalSpending()
            calculateRemainingTotalBudget()
        }

    func updateAfterTransactionChange() {
        let totalSpent = calculateTotalSpending()
        totalBudgetUsed = totalSpent // Ensure this reflects in calculations
        totalBudgetRemaining = max(0, totalBudget - totalBudgetUsed)
        totalBudgetSpentPercentage = (totalBudget > 0) ? (totalBudgetUsed / totalBudget) * 100 : 0

        print("Updated Total Budget: \(totalBudget)")
        print("Total Budget Used: \(totalBudgetUsed)")
        print("Total Budget Remaining: \(totalBudgetRemaining)")
        print("Total Budget Spent Percentage: \(totalBudgetSpentPercentage)%")
    }

    
    func calculateTotalBudgetUsed() {
        // Assuming this should match totalSpending directly
        totalBudgetUsed = totalSpending
        print("Total Budget Used: \(totalBudgetUsed)")
    }
    
    func updateTotalBudget(limit: Double, startDate: Date, endDate: Date) {
        guard let userId = KeychainManager.shared.getUserId() else {
            print("User not logged in or user ID not available")
            return
        }
        
        do {
            try DatabaseManager.shared.setTotalBudget(userId: userId, limit: limit, startDate: startDate, endDate: endDate)
            self.totalBudget = limit // Dynamically update based on user input
            self.startDate = startDate
            self.endDate = endDate
            updateAfterTransactionChange() // Recalculate and update UI
        } catch {
            print("Error setting total budget: \(error)")
        }
    }
    
    func deleteTotalBudget() {
        // Perform the deletion logic here
        // For example, remove the budget from the dictionary and update the database
        if let userId = KeychainManager.shared.getUserId() {
            do {
                try DatabaseManager.shared.deleteTotalBudget(userId: userId)
                DispatchQueue.main.async {
                    self.budget.categories.removeValue(forKey: "Total")
                    self.totalBudgetRemaining = 0
                    self.totalBudgetSpentPercentage = 0
                    // Perform any additional updates required after deletion
                }
            } catch {
                print("Error deleting total budget: \(error)")
            }
        }
    }


    
    // Add this computed property to your TransactionViewModel
    var remainingDays: Int {
        guard let endDate = budget.categories["Total"]?.endDate else {
            return 0 // Or return an appropriate default value
        }
        let currentDate = Date()
        let remainingDays = Calendar.current.dateComponents([.day], from: currentDate, to: endDate).day ?? 0
        return max(0, remainingDays) // Ensure we don't return negative values
    }


    
    
        }

        struct CategorySpending: Identifiable {
            var id: String { category }
            let category: String
            let amount: Double
        }
        
        struct TimeSpending: Identifiable {
            var id: String { date }
            let date: String
            let amount: Double
        }
            
    struct BudgetItem: Identifiable {
            var id: String { category }
            let category: String
            let details: BudgetDetails
        }
    
    

    
    
