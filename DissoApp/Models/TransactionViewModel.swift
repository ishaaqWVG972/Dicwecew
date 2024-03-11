
import Foundation
import Swift
import Combine
import UIKit

enum TimeFrame: Hashable {
    case lastWeek, lastMonth, thisMonth, thisWeek, specificMonth(Int, Int), allTime // month, year
}
    


extension DateFormatter {
    func monthAndYearString(from date: Date) -> String? {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        guard let year = components.year, let month = components.month else { return nil }
        return String(format: "%02d-%d", month, year)
    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
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
    
    @Published var spendingComparisonByCategory: Double = 0 
    let databaseManager = DatabaseManager.shared
    
    @Published var recognizedText: CategorizedText = CategorizedText()
        @Published var isProcessing = false
    
     var cancellables = Set<AnyCancellable>()
//       let textRecognitionService = TextRecognitionService()
       let textCategorizer = TextCategorizer()
//    @Published var isProcessing = false
//      @Published var recognizedText = CategorizedText()
//      var textCategorizer = TextCategorizer()
    
    @Published var productEntries: [ProductEntry] = []
    @Published var selectedDate: Date = Date()
    var userId: Int64 = 123
    @Published var productMappings: [String: [String]] = [:]
    
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
    
    
    func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let empty = [Int](repeating:0, count: s2.count)
        var last = [Int](0...s2.count)

        for (i, char1) in s1.enumerated() {
            var cur = [i + 1] + empty
            for (j, char2) in s2.enumerated() {
                cur[j + 1] = char1 == char2 ? last[j] : Swift.min(last[j], last[j + 1], cur[j]) + 1
            }
            last = cur
        }
        return last.last!
    }
    
    
    func updateProductMappings(with userInput: String) {
         let lowercasedInput = userInput.lowercased()

         // Attempt to find the closest match among existing canonical names
         let closestMatch = productMappings.keys.min { a, b in
             levenshteinDistance(lowercasedInput, a) < levenshteinDistance(lowercasedInput, b)
         }

         // Decide if the closest match is close enough to consider the same product
         if let match = closestMatch, levenshteinDistance(lowercasedInput, match) <= 8{ // Threshold can be adjusted
             // Add the user input to the variations for this canonical name
             productMappings[match, default: []].append(userInput)
         } else {
             // Treat the user input as a new canonical name
             productMappings[lowercasedInput] = [userInput]
         }
     }
    
    func findClosestCanonicalName(for userInput: String, using mappings: [(canonical: String, variation: String)]) -> String? {
          var closestMatch: (canonical: String, distance: Int)? = nil

          for mapping in mappings {
              let distance = levenshteinDistance(userInput.lowercased(), mapping.variation.lowercased())
              if closestMatch == nil || distance < closestMatch!.distance {
                  closestMatch = (canonical: mapping.canonical, distance: distance)
              }
          }

          // Define a threshold for what you consider a "close" match
          let threshold = 8 // Adjust based on your needs
          if let match = closestMatch, match.distance <= threshold {
              return match.canonical
          } else {
              return nil
          }
      }
    
    func findCanonicalNameForItem(_ item: String) -> String? {
           do {
               // Fetch all mappings from the database
               let mappings = try DatabaseManager.shared.fetchAllMappings()

               // Initialize a variable to keep track of the closest match
               var closestMatch: (canonical: String, distance: Int) = ("", Int.max)

               // Iterate through each mapping to find the closest canonical name based on the Levenshtein Distance
               for mapping in mappings {
                   let distance = levenshteinDistance(item.lowercased(), mapping.variation.lowercased())
                   if distance < closestMatch.distance {
                       closestMatch = (mapping.canonical, distance)
                   }
               }

               // Assuming a threshold for determining a "close enough" match
               let threshold = 8
               return closestMatch.distance <= threshold ? closestMatch.canonical : item
           } catch {
               print("Error fetching mappings: \(error)")
               return nil
           }
       }

    
    func calculateCheapestStore(for items: [String], userId: Int64, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Fetch the cheapest options considering canonical names
                let cheapestOptions = try DatabaseManager.shared.fetchCheapestOptionsConsideringCanonicalNames(for: items)

                // Aggregate prices for each item in each store
                var storePrices: [String: Double] = [:] // StoreName: TotalPrice

                for (item, store) in cheapestOptions {
                    if let price = try? DatabaseManager.shared.fetchPriceForItemInStore(item: item, store: store) {
                        storePrices[store, default: 0.0] += price ?? 0.0
                    }
                }


                // Determine the store with the lowest total price
                if let cheapestStore = storePrices.min(by: { $0.value < $1.value }) {
                    DispatchQueue.main.async {
                        completion(.success(cheapestStore.key))
                    }
                } else {
                    throw NSError(domain: "com.yourapp.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to find the cheapest store."])
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    
    
    func handleNewProductInput(for productName: String) {
        print("Handling product mapping for: \(productName)")
        
        // Attempt to fetch all mappings from the database
        do {
            let mappings = try DatabaseManager.shared.fetchAllMappings()
            print("Fetched mappings from database. Total mappings count: \(mappings.count)")
            
            // Determine the closest canonical name or decide it's a new canonical name
            let closestCanonicalName = self.findClosestCanonicalName(for: productName, using: mappings)
            
            if let closestName = closestCanonicalName {
                print("Closest canonical name found for '\(productName)': \(closestName)")
            } else {
                print("No close match found. Treating '\(productName)' as a new canonical name.")
            }
            
            // Insert or update the product mapping in the database
            try DatabaseManager.shared.insertOrUpdateProductMapping(userInput: productName, canonicalName: closestCanonicalName)
            
            print("Product mapping insertion or update completed for: \(productName)")
        } catch {
            print("Error handling product mapping: \(error)")
        }
    }

    
    func suggestProductMatch(for userInput: String) -> (matchFound: Bool, suggestedNames: [String], isExactMatch: Bool) {
        do {
            let mappings = try DatabaseManager.shared.fetchAllMappings()
            let lowercasedInput = userInput.lowercased()

            // Filter for similar mappings
            let similarMappings = mappings.filter { mapping in
                mapping.variation.lowercased().contains(lowercasedInput) || lowercasedInput.contains(mapping.variation.lowercased())
            }

            // If an exact match is found, suggest using the existing canonical name
            if let exactMatch = mappings.first(where: { $0.variation.lowercased() == lowercasedInput }) {
                return (true, [exactMatch.canonical], true)
            }
            
            let suggestedNames = similarMappings.map { $0.canonical }.uniqued()
            return (!suggestedNames.isEmpty, suggestedNames, false)
        } catch {
            print("Error fetching mappings: \(error)")
            return (false, [], false)
        }
    }
    
    func handleUserConfirmation(for userInput: String, withSuggestedCanonicalName suggestedCanonicalName: String?, isExactMatch: Bool) {
        do {
            if let suggestedCanonicalName = suggestedCanonicalName, !isExactMatch {
                // Link the new variation to the existing canonical name
                try DatabaseManager.shared.insertOrUpdateProductMapping(userInput: userInput, canonicalName: suggestedCanonicalName)
            } else if !isExactMatch {
                // Treat the user input as a new canonical name and variation
                try DatabaseManager.shared.insertOrUpdateProductMapping(userInput: userInput)
            }
            // If it's an exact match, no need to insert or update, as it already exists
        } catch {
            print("Error updating product mappings: \(error)")
        }
    }


    func extractKeywords(from input: String) -> [String] {
        // A simple keyword extraction that splits by spaces. Consider using more sophisticated NLP techniques.
        let keywords = input.components(separatedBy: " ").filter { !$0.isEmpty }
        print("Extracted Keywords: \(keywords)")
        return keywords
    }




    
    func processText(from text: String) {
           isProcessing = true
           
           // Assuming textCategorizer has a method to process a single string
           // and return a CategorizedText object. If not, you'll need to implement
           // this logic based on your app's specific requirements.
           let categorizedText = textCategorizer.categorizeTextBlocks([text])

           // Update UI
           DispatchQueue.main.async {
               self.recognizedText = categorizedText
               self.isProcessing = false
           }
       }
    
    func resetTransactionDetails() {
         productEntries.removeAll()
         selectedDate = Date()
         // Reset any other properties as needed
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

    func closestCategoryToLimit() -> (category: String, limit: Double, remaining: Double, spentPercentage: Double, remainingDays: Int)? {
        let categoryBudgets = budget.categories.filter { $0.key != "Total" && $0.value.limit > 0 }
        let currentDate = Date()
        let calendar = Calendar.current
        let closestCategory = categoryBudgets.min(by: { (a, b) -> Bool in
            let aSpentPercentage = (budget.spent[a.key] ?? 0) / a.value.limit
            let bSpentPercentage = (budget.spent[b.key] ?? 0) / b.value.limit
            return aSpentPercentage > bSpentPercentage
        })

        guard let categoryDetails = closestCategory else { return nil }
        let spentAmount = budget.spent[categoryDetails.key] ?? 0
        let remaining = categoryDetails.value.limit - spentAmount
        let spentPercentage = spentAmount / categoryDetails.value.limit
        let remainingDays = calendar.dateComponents([.day], from: currentDate, to: categoryDetails.value.endDate).day ?? 0

        return (categoryDetails.key, categoryDetails.value.limit, remaining, spentPercentage, remainingDays)
    }


    // In TransactionViewModel

    func spendingComparisonByAllCategories() -> [String: (lastMonth: Double, thisMonth: Double)] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        let now = Date()
        let calendar = Calendar.current
        let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfCurrentMonth)!
        
        // Fetch categories from the transactions dynamically
        let categories = Set(transactions.compactMap { $0.categoryName })
        
        var comparisons: [String: (lastMonth: Double, thisMonth: Double)] = [:]
        
        for category in categories {
            let transactionsThisMonth = transactions.filter { transaction in
                guard let transactionDate = dateFormatter.date(from: transaction.userSelectedDate),
                      transactionDate >= startOfCurrentMonth,
                      transaction.categoryName == category else {
                    return false
                }
                return true
            }
            
            let transactionsLastMonth = transactions.filter { transaction in
                guard let transactionDate = dateFormatter.date(from: transaction.userSelectedDate),
                      transactionDate >= startOfLastMonth && transactionDate < startOfCurrentMonth,
                      transaction.categoryName == category else {
                    return false
                }
                return true
            }
            
            let totalThisMonth = transactionsThisMonth.reduce(0) { $0 + $1.totalPrice }
            let totalLastMonth = transactionsLastMonth.reduce(0) { $0 + $1.totalPrice }
            
            comparisons[category] = (totalLastMonth, totalThisMonth)
        }
        
        return comparisons
    }
    
    func findSavingsOpportunities() -> [ProductSavings] {
        var productPrices: [String: [StorePrice]] = [:] // Product name mapped to stores, prices, and categories

        // Aggregate prices for each product at different stores, including category
        for transaction in transactions {
            let category = transaction.categoryName ?? "Unknown" // Assuming you have categoryName in Transaction
            for product in transaction.products {
                let productName = product.name
                let storeName = transaction.companyName
                let price = product.price

                let storePrice = StorePrice(store: storeName, price: price, category: category)
                if var prices = productPrices[productName] {
                    if let index = prices.firstIndex(where: { $0.store == storeName && $0.category == category }) {
                        // Update price if the new price is lower within the same category
                        prices[index].price = min(prices[index].price, price)
                    } else {
                        prices.append(storePrice)
                    }
                    productPrices[productName] = prices
                } else {
                    productPrices[productName] = [storePrice]
                }
            }
        }

        // Analyze data to find savings opportunities, now including category information
        var savingsOpportunities: [ProductSavings] = []
        for (product, storePrices) in productPrices {
            guard let cheapest = storePrices.min(by: { $0.price < $1.price }),
                  let mostExpensive = storePrices.max(by: { $0.price < $1.price }),
                  cheapest.price < mostExpensive.price else { continue }

            let savings = ProductSavings(productName: product,
                                          cheapestStore: cheapest.store,
                                          mostExpensiveStore: mostExpensive.store,
                                          savingsAmount: mostExpensive.price - cheapest.price,
                                          category: cheapest.category) // Use the category of the cheapest price as the product's category
            savingsOpportunities.append(savings)
        }

        return savingsOpportunities.sorted(by: { $0.savingsAmount > $1.savingsAmount })
    }

    
    
    
    
    
    
    var savingsOpportunities: [ProductSavings] {
         // Assuming findSavingsOpportunities() is your method that returns [ProductSavings]
         return findSavingsOpportunities().sorted(by: { $0.savingsAmount > $1.savingsAmount })
     }

    // In TransactionViewModel
    var categories: [String] {
        // Extract unique categories from transactions, assuming transactions have a categoryName property
        let uniqueCategories = Set(transactions.compactMap { $0.categoryName }).sorted()
        return uniqueCategories
    }

    func totalSpentInCurrentPeriod() -> Double {
          return transactions.filter { transaction in
              guard let transactionDate = parseDate(transaction.userSelectedDate) else { return false }
              return transactionDate >= startDate && transactionDate <= endDate
          }.reduce(0) { sum, transaction in
              sum + transaction.totalPrice
          }
      }

      // Find the most expensive transaction in the current period
      func mostExpensiveTransaction() -> Transaction? {
          return transactions.filter { transaction in
              guard let transactionDate = parseDate(transaction.userSelectedDate) else { return false }
              return transactionDate >= startDate && transactionDate <= endDate
          }.max(by: { $0.totalPrice < $1.totalPrice })
      }
    
    
    func monthToMonthComparison() -> String {
        // Assuming you have a way to fetch transactions and that each transaction has a date and amount.
        let calendar = Calendar.current
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        // Calculate start and end dates for the current month
        let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfCurrentMonth = calendar.date(byAdding: .month, value: 1, to: startOfCurrentMonth)!
        
        // Calculate start and end dates for the previous month
        let startOfPreviousMonth = calendar.date(byAdding: .month, value: -1, to: startOfCurrentMonth)!
        let endOfPreviousMonth = startOfCurrentMonth
        
        // Filter transactions for the current and previous months
        let currentMonthTransactions = transactions.filter { transaction in
            guard let date = dateFormatter.date(from: transaction.userSelectedDate) else { return false }
            return date >= startOfCurrentMonth && date < endOfCurrentMonth
        }
        
        let previousMonthTransactions = transactions.filter { transaction in
            guard let date = dateFormatter.date(from: transaction.userSelectedDate) else { return false }
            return date >= startOfPreviousMonth && date < endOfPreviousMonth
        }
        
        // Sum up the amounts for each month
        let currentMonthTotal = currentMonthTransactions.reduce(0) { $0 + $1.totalPrice }
        let previousMonthTotal = previousMonthTransactions.reduce(0) { $0 + $1.totalPrice }
        
        // Calculate the percentage difference
        if previousMonthTotal == 0 {
            return "No spending data available for the previous month."
        }
        
        let percentageDifference = ((currentMonthTotal - previousMonthTotal) / previousMonthTotal) * 100
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        let percentageString = formatter.string(from: NSNumber(value: percentageDifference)) ?? ""
        
        let comparisonResult = percentageDifference > 0 ? "more" : "less"
        
        return "You spent \(percentageString) \(comparisonResult) this month compared to last."
    }
    
    
    func highestAndLowestSpendingMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        // Aggregate spending by month and year
        var monthlySpending = [String: Double]() // Format: "MM-yyyy": totalSpending
        for transaction in transactions {
            guard let date = dateFormatter.date(from: transaction.userSelectedDate),
                  let monthYear = dateFormatter.monthAndYearString(from: date) else {
                continue
            }
            monthlySpending[monthYear, default: 0] += transaction.totalPrice
        }
        
        // Find the month with the highest and lowest spending
        guard let highestSpendingEntry = monthlySpending.max(by: { $0.value < $1.value }),
              let lowestSpendingEntry = monthlySpending.min(by: { $0.value < $1.value }) else {
            return "Not enough data to determine highest and lowest spending months."
        }
        
        // Format the output
        let highestMonth = highestSpendingEntry.key
        let highestAmount = highestSpendingEntry.value
        let lowestMonth = lowestSpendingEntry.key
        let lowestAmount = lowestSpendingEntry.value
        
        return "Highest spending month: \(highestMonth) with £\(String(format: "%.2f", highestAmount)).\nLowest spending month: \(lowestMonth) with £\(String(format: "%.2f", lowestAmount))."
    }


    func averageMonthlySpending() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        // Aggregate spending by month and year
        var monthlySpending = [String: Double]() // Format: "MM-yyyy": totalSpending
        for transaction in transactions {
            guard let date = dateFormatter.date(from: transaction.userSelectedDate),
                  let monthYear = dateFormatter.monthAndYearString(from: date) else {
                continue
            }
            monthlySpending[monthYear, default: 0] += transaction.totalPrice
        }
        
        // Calculate average spending
        let totalSpending = monthlySpending.values.reduce(0, +)
        let averageSpending = monthlySpending.isEmpty ? 0 : totalSpending / Double(monthlySpending.count)
        
        return String(format: "Average monthly spending: £%.2f", averageSpending)
    }

    func calculateBudgetVsActual() -> [BudgetVsActual] {
        guard let userId = KeychainManager.shared.getUserId() else {
            print("User not logged in or user ID not available")
            return []
        }

        var comparisons: [BudgetVsActual] = []
        var totalActualSpending: Double = 0

        do {
            let userBudgets = try DatabaseManager.shared.fetchUserBudgets(userId: userId)
            let aggregatedSpending = getAggregatedSpendingByCategory()

            // Calculate and add category-specific budgets
            for (category, budgetDetails) in userBudgets {
                guard category != "Total" else {
                    // Skip the "Total" category here, handle it separately
                    continue
                }
                let actualSpending = aggregatedSpending.first(where: { $0.category == category })?.amount ?? 0.0
                totalActualSpending += actualSpending // Sum up actual spending for the total budget calculation
                let comparison = BudgetVsActual(category: category, budgeted: budgetDetails.limit, actual: actualSpending)
                comparisons.append(comparison)
            }

            // Handle the total budget separately
            if let totalBudgetDetails = userBudgets["Total"] {
                let totalComparison = BudgetVsActual(category: "Total", budgeted: totalBudgetDetails.limit, actual: totalActualSpending)
                comparisons.append(totalComparison)
            }
        } catch {
            print("Error calculating budget vs. actual spending: \(error)")
        }
        
        return comparisons
    }


    func topTransactionCategory() -> String {
        let categoryCounts = transactions.reduce(into: [String: Int]()) { counts, transaction in
            // Assuming `categoryName` is the property you want to count occurrences of.
            let category = transaction.categoryName ?? "Unknown"
            counts[category, default: 0] += 1
        }
        
        if let topCategory = categoryCounts.max(by: { $0.value < $1.value })?.key {
            return "Top category: \(topCategory) with \(categoryCounts[topCategory]!) transactions."
        } else {
            return "No transactions found."
        }
    }

    


    
    func calculateImpactOfProductOnBudget(category: String, price: Double) {
        // Ensure the category exists within the budget
        guard let budgetDetails = budget.categories[category] else { return }
        
        // Calculate the new spent amount for this category
        let currentSpentAmount = budget.spent[category] ?? 0
        let newSpentAmount = currentSpentAmount + price
        
        // Update the spent dictionary with the new spent amount
        budget.spent[category] = newSpentAmount
        
        // Optionally, perform any logic needed based on the new spent amount
        // For example, checking if the new spent amount exceeds the budget limit
        if newSpentAmount > budgetDetails.limit {
            print("Warning: Spending for \(category) exceeds the budget limit.")
        }
        
        // Since you're tracking total spending separately,
        // you may want to update any related total spending and remaining budget calculations here as well
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
    
struct StorePrice {
    var store: String
    var price: Double
    var category: String
}

struct ProductSavings: Identifiable {
    var id = UUID()
    var productName: String
    var cheapestStore: String
    var mostExpensiveStore: String
    var savingsAmount: Double
    var category: String
   
}

    
struct BudgetVsActual {
    let category: String
    let budgeted: Double
    let actual: Double
    var difference: Double { actual - budgeted }
}

