
import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()
    private var database: Connection!
    
    
    // Define your tables
     let users = Table("users")
     let tokens = Table("tokens")
     let transactions = Table("transactions")
     let products = Table("products")
     let categories = Table("categories")
     let budgets = Table("budgets")
    
    // Define columns for each table
    // Example for 'users' table
     let userId = Expression<Int64>("id")
     let userName = Expression<String>("name")
     let userEmail = Expression<String>("email")
     let userPasswordHash = Expression<String>("password_hash")
    
//     Columns for the Transaction table
       let transactionId = Expression<String>("id") // UUIDs as Strings
       let transactionCompanyName = Expression<String>("company_name")
       let transactionTotalPrice = Expression<Double>("total_price")
       let transactionUserSelectedDate = Expression<String?>("user_selected_date")
       let transactionUserId = Expression<Int64>("user_id")
       let transactionCategoryId = Expression<Int64?>("category_id") // Optional category reference
  
      // Columns for the Product table
       let productId = Expression<String>("id") // UUIDs as Strings
       let productName = Expression<String>("name")
       let productPrice = Expression<Double>("price")
       let productTransactionId = Expression<String>("transaction_id")
       let productCompanyName = Expression<String>("company_name")

//       Columns for the Token table
       let tokenId = Expression<String>("id") // UUIDs as Strings
       let tokenValue = Expression<String>("value")
       let tokenUserId = Expression<Int64>("user_id")
  
      private let categoryId = Expression<Int64>("id")
      private let categoryName = Expression<String>("name")
    
    //Column for budget table
     let budgetId = Expression<Int64>("id")
     let budgetUserId = Expression<Int64>("user_id")
     let budgetCategoryName = Expression<String?>("category_name") // Nullable for total budget
     let budgetLimit = Expression<Double>("limit")
     let budgetTimeFrame = Expression<String>("time_frame")
     let budgetStartDate = Expression<Date>("start_date")
    private let budgetEndDate = Expression<Date>("end_date")

     let productMappings = Table("productMappings")
     let mappingId = Expression<Int64>("id")
     let canonicalName = Expression<String>("canonicalName")
     let variationName = Expression<String>("variationName")
    
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
            try createProductMappingsTable()
            
         
            
            print("All tables created successfully")
        } catch {
            print("Database initialization failed: \(error)")
        }
    }
    
     func createUserTable() throws {
        try database.run(users.create(ifNotExists: true) { t in
            t.column(userId, primaryKey: .autoincrement)
            t.column(userName)
            t.column(userEmail, unique: true)
            t.column(userPasswordHash)
        })
        print("Users table created")
    }
    
     func createTransactionsTable() throws {
           try database.run(transactions.create(ifNotExists: true) { t in
               t.column(transactionId, primaryKey: true) // UUID as String
               t.column(transactionCompanyName)
               t.column(transactionTotalPrice)
               t.column(transactionUserSelectedDate)
               t.column(transactionUserId)
               t.column(transactionCategoryId)// No foreign key constraint to 'users', handled in app logic
           })
       }
   
        func createProductsTable() throws {
           try database.run(products.create(ifNotExists: true) { t in
               t.column(productId, primaryKey: true) // UUID as String
               t.column(productName)
               t.column(productPrice)
               t.column(productTransactionId)
               t.column(productCompanyName)
              
           })
       }
   
        func createTokensTable() throws {
           try database.run(tokens.create(ifNotExists: true) { t in
               t.column(tokenId, primaryKey: true) // UUID as String
               t.column(tokenValue)
               t.column(tokenUserId) // No foreign key constraint to 'users', handled in app logic
           })
       }
   
        func createCategoriesTable() throws{
           try database.run(categories.create(ifNotExists:true){t in
               t.column(categoryId, primaryKey: .autoincrement)
               t.column(categoryName)
              
           })
       }
    
     func createBudgetsTable() throws {
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
    
    
     func createProductMappingsTable() throws {
        try database.run(productMappings.create(ifNotExists: true) { t in
            t.column(mappingId, primaryKey: .autoincrement)
            t.column(canonicalName)
            t.column(variationName, unique: true)
        })
        print("ProductMappings table created")
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
            let idString = productRow[productId]
            let variationName = productRow[productName]
            let price = productRow[productPrice]

            guard let uuid = UUID(uuidString: idString) else { continue }
            
            // Assuming you have a method to fetch the canonical name for a given variation
            let canonicalName = try canonicalNameForItem(variationName)

            let product = Product(id: uuid, name: canonicalName, price: price)
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
        // This dictionary maps items to their canonical names. You'll need to populate it accordingly.
        var itemToCanonicalNameMap: [String: String] = [:]
        
        // Populate itemToCanonicalNameMap by fetching mappings from the database
        let allMappings = try fetchAllMappings()
        allMappings.forEach { mapping in
            itemToCanonicalNameMap[mapping.variation] = mapping.canonical
        }
        
        var cheapestOptions = [String: String]()
        for item in items {
            // Use canonical name if available, else use item itself
            let canonicalOrOriginalName = itemToCanonicalNameMap[item] ?? item
            
            // Adjust the query to filter by productName instead
            // This assumes that productName stores the variation name
            let query = products.filter(productName == canonicalOrOriginalName).order(productPrice.asc)
            
            // Attempt to find the cheapest product for the canonical/variation name
            if let cheapestProductRow = try database.pluck(query) {
                let company = cheapestProductRow[productCompanyName]
                cheapestOptions[item] = company // Mapping original item name to company for simplicity
            }
        }
        return cheapestOptions
    }


    
    func calculateTotalCostPerStore(for items: [String]) throws -> [String: Double] {
        var totalCostPerStore = [String: Double]()
        
        // Fetch canonical names for items
        let canonicalItems = try items.map { try canonicalNameForItem($0) }
        
        // Fetch unique stores from products
        let uniqueStores = Set(try database.prepare(products.select(productCompanyName)).map { $0[productCompanyName] })
        
        for store in uniqueStores {
            var storeTotalCost = 0.0
            
            for item in canonicalItems {
                let query = products
                    .filter(productCompanyName == store && canonicalName == item) // Use canonical name
                    .order(productPrice.asc)
                
                if let product = try database.pluck(query) {
                    storeTotalCost += product[productPrice]
                }
            }
            
            totalCostPerStore[store] = storeTotalCost
        }
        
        return totalCostPerStore
    }

    // This function calculates which store will be the cheapest based on the total cost of items in the shopping list.
    func calculateCheapestStore(for items: [String], userId: Int64) throws -> String {
        // Fetch canonical names for items
        let canonicalItems = try items.map { try canonicalNameForItem($0) }
        
        // Calculate total cost per store
        let totalCostPerStore = try calculateTotalCostPerStore(for: canonicalItems)
        
        // Find the store with the lowest total cost
        if let cheapest = totalCostPerStore.min(by: { $0.value < $1.value }) {
            return cheapest.key
        } else {
            throw NSError(domain: "DatabaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to determine the cheapest store based on item availability."])
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

    
    
    
    func insertOrUpdateProductMapping(userInput: String, canonicalName: String? = nil) throws {
        let insert = productMappings.insert(
            self.canonicalName <- (canonicalName ?? userInput),
            self.variationName <- userInput
        )
        try database.run(insert)
    }



    
    func fetchAllMappings() throws -> [(canonical: String, variation: String)] {
        let mappingsQuery = productMappings.select(canonicalName, variationName)
        var mappings: [(canonical: String, variation: String)] = []
        
        for mapping in try database.prepare(mappingsQuery) {
            let fetchedMapping = (canonical: mapping[canonicalName], variation: mapping[variationName])
            // Print each mapping as it's fetched to provide insight into what's being returned.
            print("Fetched mapping: Canonical Name - '\(fetchedMapping.canonical)', Variation Name - '\(fetchedMapping.variation)'")
            mappings.append(fetchedMapping)
        }
        
        // Log the total number of mappings fetched for a high-level overview.
        print("Total mappings fetched: \(mappings.count)")
        
        return mappings
    }


    
 
    func canonicalNameForItem(_ itemName: String) throws -> String {
        let query = productMappings.filter(variationName == itemName)
        if let mapping = try database.pluck(query) {
            return mapping[canonicalName]
        }
        return itemName // Return the item name itself if no mapping found
    }

    func fetchCheapestOptionsConsideringCanonicalNames(for items: [String]) throws -> [String: String] {
        // Fetch all mappings from the database to build a map of canonical names to their variations
        let allMappings = try fetchAllMappings()
        var canonicalToVariationsMap: [String: [String]] = [:]
        
        // Populate the map
        allMappings.forEach { mapping in
            canonicalToVariationsMap[mapping.canonical, default: []].append(mapping.variation)
        }
        
        var cheapestOptions = [String: String]()
        
        // Iterate over each item in the shopping list
        for item in items {
            // Find the canonical name for the item, if available
            let canonicalName = allMappings.first(where: { $0.variation == item })?.canonical ?? item
            // Find all variations for this canonical name, including the item itself
            let variations = canonicalToVariationsMap[canonicalName, default: [item]]
            
            var cheapestPrice: Double = Double.infinity
            var cheapestCompany: String?
            
            // Check each variation to find the cheapest option
            for variation in variations {
                let query = products.filter(productName == variation).order(productPrice.asc)
                if let cheapestProductRow = try database.pluck(query), cheapestProductRow[productPrice] < cheapestPrice {
                    cheapestPrice = cheapestProductRow[productPrice]
                    cheapestCompany = cheapestProductRow[productCompanyName]
                }
            }
            
            // If a cheapest option was found among the variations, add it to the result
            if let company = cheapestCompany {
                cheapestOptions[item] = company
            }
        }
        
        return cheapestOptions
    }
    
    
    func fetchPriceForItemInStore(item: String, store: String) throws -> Double? {
        let query = products.filter(productName == item && productCompanyName == store).order(productPrice.asc)
        guard let product = try database.pluck(query) else { return nil }
        return product[productPrice]
    }
    

}

