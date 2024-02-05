
import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()
    private var database: Connection!
    
    // Define your tables
    private let users = Table("users")
    private let tokens = Table("tokens")
    private let transactions = Table("transactions")
    private let products = Table("products")
    private let categories = Table("categories")
    private let budgets = Table("budgets")
    
    // Define columns for each table
    // Example for 'users' table
    private let userId = Expression<Int64>("id")
    private let userName = Expression<String>("name")
    private let userEmail = Expression<String>("email")
    private let userPasswordHash = Expression<String>("password_hash")
    
//     Columns for the Transaction table
      private let transactionId = Expression<String>("id") // UUIDs as Strings
      private let transactionCompanyName = Expression<String>("company_name")
      private let transactionTotalPrice = Expression<Double>("total_price")
      private let transactionUserSelectedDate = Expression<String?>("user_selected_date")
      private let transactionUserId = Expression<Int64>("user_id")
      private let transactionCategoryId = Expression<Int64?>("category_id") // Optional category reference
  
      // Columns for the Product table
      private let productId = Expression<String>("id") // UUIDs as Strings
      private let productName = Expression<String>("name")
      private let productPrice = Expression<Double>("price")
      private let productTransactionId = Expression<String>("transaction_id")
      private let productCompanyName = Expression<String>("company_name")

//       Columns for the Token table
      private let tokenId = Expression<String>("id") // UUIDs as Strings
      private let tokenValue = Expression<String>("value")
      private let tokenUserId = Expression<Int64>("user_id")
  
      private let categoryId = Expression<Int64>("id")
      private let categoryName = Expression<String>("name")
    
    //Column for budget table
    private let budgetId = Expression<Int64>("id")
    private let budgetUserId = Expression<Int64>("user_id")
    private let budgetCategoryName = Expression<String?>("category_name") // Nullable for total budget
    private let budgetLimit = Expression<Double>("limit")
    private let budgetTimeFrame = Expression<String>("time_frame")
    private let budgetStartDate = Expression<Date>("start_date")
    private let budgetEndDate = Expression<Date>("end_date")


    
    
    init() {
        do {
            // Database path
            let documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentsDirectory.appendingPathComponent("db.sqlite3")
            database = try Connection(fileUrl.path)

            // Create tables
            try createUserTable()
            try createTransactionsTable()
            try createProductsTable()
            try createCategoriesTable()
            try createBudgetsTable()
            
         
            
            print("All tables created successfully")
        } catch {
            print("Database initialization failed: \(error)")
        }
    }
    
    private func createUserTable() throws {
        try database.run(users.create(ifNotExists: true) { t in
            t.column(userId, primaryKey: .autoincrement)
            t.column(userName)
            t.column(userEmail, unique: true)
            t.column(userPasswordHash)
        })
        print("Users table created")
    }
    
    private func createTransactionsTable() throws {
           try database.run(transactions.create(ifNotExists: true) { t in
               t.column(transactionId, primaryKey: true) // UUID as String
               t.column(transactionCompanyName)
               t.column(transactionTotalPrice)
               t.column(transactionUserSelectedDate)
               t.column(transactionUserId)
               t.column(transactionCategoryId)// No foreign key constraint to 'users', handled in app logic
           })
       }
   
       private func createProductsTable() throws {
           try database.run(products.create(ifNotExists: true) { t in
               t.column(productId, primaryKey: true) // UUID as String
               t.column(productName)
               t.column(productPrice)
               t.column(productTransactionId)
               t.column(productCompanyName)
              
           })
       }
   
       private func createTokensTable() throws {
           try database.run(tokens.create(ifNotExists: true) { t in
               t.column(tokenId, primaryKey: true) // UUID as String
               t.column(tokenValue)
               t.column(tokenUserId) // No foreign key constraint to 'users', handled in app logic
           })
       }
   
       private func createCategoriesTable() throws{
           try database.run(categories.create(ifNotExists:true){t in
               t.column(categoryId, primaryKey: .autoincrement)
               t.column(categoryName)
              
           })
       }
    
    private func createBudgetsTable() throws {
        try database.run(budgets.create(ifNotExists: true) { t in
            t.column(budgetId, primaryKey: true)
            t.column(budgetUserId)
            t.column(budgetCategoryName)
            t.column(budgetLimit)
            t.column(budgetTimeFrame) // New column
            t.column(budgetStartDate) // New column
            t.column(budgetEndDate)
        })
        print("Budgets table created")
    }
    
    
    //  CRUD operations
        func registerUser(name: String, email: String, passwordHash: String) {
            let insert = users.insert(userName <- name, userEmail <- email, userPasswordHash <- passwordHash)
            do {
                try database.run(insert)
                print("User registered successfully: \(name)")
            } catch {
                print("Error registering user: \(error)")
            }
        }
    
        func authenticateUser(email: String, password: String) throws -> Bool {
            let query = users.filter(self.userEmail == email && self.userPasswordHash == password)
            let count = try database.scalar(query.count)
            return count > 0
        }
    
    
        func authenticateUserAndGetUserId(email: String, password: String) throws -> Int64? {
            let query = users.filter(self.userEmail == email && self.userPasswordHash == password)
            if let userRow = try database.pluck(query) {
                let id = userRow[userId]
                print("User authenticated successfully. User ID: \(id)")
                return id
            } else {
                print("User authentication failed: User not found or incorrect password.")
                return nil
            }
        }
    
        func addTransaction(companyName: String, totalPrice: Double, userSelectedDate: String, products: [Product], userId: Int64, categoryId: Int64?) throws {
            let transactionUUID = UUID().uuidString
            let insertTransaction = transactions.insert(
                self.transactionId <- transactionUUID,
                self.transactionCompanyName <- companyName,
                self.transactionTotalPrice <- totalPrice,
                self.transactionUserSelectedDate <- userSelectedDate,
                self.transactionUserId <- userId,
                self.transactionCategoryId <- categoryId
            )
            let transactionRowId = try database.run(insertTransaction)
            for product in products {
                let insertProduct = self.products.insert(
                    self.productId <- UUID().uuidString,
                    self.productName <- product.name,
                    self.productPrice <- product.price,
                    self.productCompanyName <- companyName,
                    self.productTransactionId <- transactionUUID
                    
                )
                try database.run(insertProduct)
            }
        }
    
    
        func fetchAllTransactions(for userId: Int64) throws -> [Transaction] {
            var allTransactions = [Transaction]()
            let query = transactions.filter(transactionUserId == userId)
            for transactionRow in try database.prepare(query) {
                let idString = transactionRow[transactionId]
                guard let uuid = UUID(uuidString: idString) else { continue }
                let companyName = transactionRow[transactionCompanyName]
                let totalPrice = transactionRow[transactionTotalPrice]
                let userSelectedDate = transactionRow[transactionUserSelectedDate] ?? ""
                let categoryId = transactionRow[transactionCategoryId]
    
                let category = categoryId != nil ? try fetchCategory(for: categoryId!) : nil
                let products = try fetchProducts(forTransactionId: uuid)
    
                let transaction = Transaction(
                    id: uuid,
                    companyName: companyName,
                    createdAt: nil, // Assuming you don't have a creation date
                    products: products,
                    userSelectedDate: userSelectedDate,
                    categoryId: categoryId
                )
                allTransactions.append(transaction)
            }
            return allTransactions
        }
    
    
         func fetchProducts(forTransactionId transactionId: UUID) throws -> [Product] {
            var productsArray = [Product]()
            let query = products.filter(productTransactionId == transactionId.uuidString)
            for productRow in try database.prepare(query) {
                // Extract product details
                let idString = productRow[productId]
                let name = productRow[productName]
                let price = productRow[productPrice]
    
                // Convert String to UUID
                guard let uuid = UUID(uuidString: idString) else { continue }
    
                let product = Product(id: uuid, name: name, price: price)
                productsArray.append(product)
            }
            return productsArray
        }
    
    
    func deleteTransaction(transactionId: UUID) throws {
          let transactionToDelete = transactions.filter(self.transactionId == transactionId.uuidString)
          try database.run(transactionToDelete.delete())
          
          // Optionally, if you want to delete associated products as well:
          let productsToDelete = products.filter(self.productTransactionId == transactionId.uuidString)
          try database.run(productsToDelete.delete())
      }
    
        func addCategory(name: String) throws {
             let insert = categories.insert(
                 self.categoryName <- name
               
             )
             let id = try database.run(insert)
             print("Inserted category with id: \(id)")
         }
    
        // Update a category in the database
        func updateCategory(id: Int64, newName: String) throws {
            let category = categories.filter(self.categoryId == id)
            let update = category.update(self.categoryName <- newName)
            try database.run(update)
            print("Category updated")
        }
    
        // Delete a category from the database
        func deleteCategory(id: Int64) throws {
            let category = categories.filter(self.categoryId == id)
            let delete = category.delete()
            try database.run(delete)
            print("Category deleted")
        }
    
        // Fetch all categories
         func fetchCategory(for categoryId: Int64) throws -> Category? {
            let query = categories.filter(self.categoryId == categoryId)
            if let categoryRow = try database.pluck(query) {
                let name = categoryRow[categoryName]
             
                return Category(id: categoryId, name: name)
            }
            return nil
        }
    
        func fetchCategories() throws -> [Category] {
            var categoriesArray = [Category]()
            for categoryRow in try database.prepare(categories) {
                let id = categoryRow[categoryId]
                let name = categoryRow[categoryName]
               
                categoriesArray.append(Category(id: id, name: name))
            }
            return categoriesArray
        }
    
    
    func fetchCategoryName(for categoryId: Int64) throws -> String? {
        let query = categories.filter(self.categoryId == categoryId)
        guard let categoryRow = try database.pluck(query) else { return nil }
        return categoryRow[categoryName]
    }
    
    func fetchCheapestOptions(for items: [String]) throws -> [String: String] {
        var cheapestOptions = [String: String]()
        for item in items {
            let query = products.filter(productName == item).order(productPrice.asc)
            if let cheapestProduct = try database.pluck(query) {
                let company = cheapestProduct[productCompanyName]
                cheapestOptions[item] = company
            }
        }
        return cheapestOptions
    }
    
    func calculateTotalCostPerStore(for items: [String]) throws -> [String: Double] {
        var totalCostPerStore = [String: Double]()
        let uniqueStores = Set(try database.prepare(products.select(productCompanyName)).map { $0[productCompanyName] })
        
        for store in uniqueStores {
            var totalCost = 0.0
            for item in items {
                let query = products.filter(productName == item && productCompanyName == store).order(productPrice.asc)
                if let product = try database.pluck(query) {
                    totalCost += product[productPrice]
                }
            }
            totalCostPerStore[store] = totalCost
        }
        return totalCostPerStore
    }
    // This function calculates which store will be the cheapest based on the total cost of items in the shopping list.
    func calculateCheapestStore(for items: [String], userId: Int64) throws -> String {
           // Step 1: Get stores where the user has shopped.
           let userStoresQuery = transactions.filter(transactionUserId == userId).select(transactionCompanyName)
           let userStores = Set(try database.prepare(userStoresQuery).map { $0[transactionCompanyName] })

           // Step 2: Check for each item if it's available in the user's stores and calculate costs.
           var storeCosts = [String: Double]()
           for store in userStores {
               var storeTotal = 0.0
               var allItemsAvailable = true

               for item in items {
                   let productQuery = products.filter(productName == item && productCompanyName == store).order(productPrice.asc)
                   if let product = try database.pluck(productQuery) {
                       storeTotal += product[productPrice]
                   } else {
                       allItemsAvailable = false
                       break
                   }
               }

               if allItemsAvailable {
                   storeCosts[store] = storeTotal
               }
           }

           // Step 3: Determine the cheapest store.
           if let cheapestStore = storeCosts.min(by: { $0.value < $1.value }) {
               return cheapestStore.key
           } else {
               throw NSError(domain: "DatabaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to determine the cheapest store based on user's shopping history and item availability."])
           }
       }
    
    func fetchDetailedCheapestOptions(for items: [String]) throws -> [String: (store: String, price: Double)] {
        var detailedOptions = [String: (store: String, price: Double)]()

        for item in items {
            let query = products.filter(productName == item).order(productPrice.asc)
            if let cheapestProduct = try database.pluck(query) {
                let store = cheapestProduct[productCompanyName]
                let price = cheapestProduct[productPrice]
                detailedOptions[item] = (store, price)
            } else {
                // If no product found, throw an error
                throw NSError(domain: "DatabaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No products found for item: \(item)"])
            }
        }

        return detailedOptions
    }
    
    func setCategoryBudget(userId: Int64, category: String, detail: BudgetDetails) throws {
        let budgetToUpdate = budgets.filter(budgetUserId == userId && budgetCategoryName == category)
        if try database.run(budgetToUpdate.update(
            budgetLimit <- detail.limit,
            budgetTimeFrame <- detail.timeFrame.rawValue,
            budgetStartDate <- detail.startDate,
            budgetEndDate <- detail.endDate
        )) == 0 {
            // No existing budget for this category, insert new
            let insert = budgets.insert(
                budgetUserId <- userId,
                budgetCategoryName <- category,
                budgetLimit <- detail.limit,
                budgetTimeFrame <- detail.timeFrame.rawValue,
                budgetStartDate <- detail.startDate,
                budgetEndDate <- detail.endDate
            )
            try database.run(insert)
        }
    }

    
    func fetchUserBudgets(userId: Int64) throws -> [String: BudgetDetails] {
        var userBudgets = [String: BudgetDetails]()
        for budgetRow in try database.prepare(budgets.filter(budgetUserId == userId)) {
            let category = budgetRow[budgetCategoryName] ?? "Total"
            let limit = budgetRow[budgetLimit]
            let timeFrame = BudgetTimeFrame(rawValue: budgetRow[budgetTimeFrame]) ?? .total
            let startDate = budgetRow[budgetStartDate]
            let endDate = budgetRow[budgetEndDate]

            userBudgets[category] = BudgetDetails(limit: limit, timeFrame: timeFrame, startDate: startDate, endDate: endDate)
        }
        return userBudgets
    }


    func setTotalBudget(userId: Int64, limit: Double, startDate: Date, endDate: Date) throws {
        // Use the user-defined limit as the budget limit, not the aggregated total of transactions.
        let totalBudgetDetail = BudgetDetails(limit: limit, timeFrame: .total, startDate: startDate, endDate: endDate)
        
        // Update or insert the "Total" budget with the user-defined limit.
        try setCategoryBudget(userId: userId, category: "Total", detail: totalBudgetDetail)
        print("Total budget set: \(limit)")
    }


    
    func deleteBudget(userId: Int64, category: String) throws {
          let budgetToDelete = budgets.filter(budgetUserId == userId && budgetCategoryName == category)
          try database.run(budgetToDelete.delete())
          print("Budget for category \(category) deleted for user \(userId)")
      }
    
    func deleteTotalBudget(userId: Int64) throws {
        let budgetToDelete = budgets.filter(budgetUserId == userId && budgetCategoryName == "Total")
        try database.run(budgetToDelete.delete())
    }


    
    
    func aggregateTransactionsTotal(userId: Int64, startDate: Date, endDate: Date) throws -> Double {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy" // Adjust based on your format
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        let query = transactions.filter(transactionUserId == userId && transactionUserSelectedDate >= startDateString && transactionUserSelectedDate <= endDateString)
        let totalSum = try database.scalar(query.select(transactionTotalPrice.sum)) ?? 0.0
        return totalSum
    }

}

