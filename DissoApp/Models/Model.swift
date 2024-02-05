
import Foundation


struct UserRegistration: Codable {
    var name: String
    var email: String
    var password: String
}

struct User: Codable {
    var id: Int
    var name: String
    var email: String
    var passwordHash: String
}

struct Token: Codable {
    var value: String
}

struct Product: Identifiable, Codable {
    let id: UUID
    var name: String
    var price: Double
   
}

struct Transaction: Identifiable, Codable {
    let id: UUID
    var companyName: String
    var createdAt: Date?
    var products: [Product]
    var totalPrice: Double {
        products.map { $0.price }.reduce(0, +)
    }
    var userSelectedDate: String
    var categoryId: Int64? // Add this line
    var categoryName: String? 
}

struct TransactionRequest: Codable {
    let id: UUID
    var companyName: String
    var products: [Product]
    var totalPrice: Double
    var userSelectedDate: String
}

struct Category: Identifiable, Codable {
    let id: Int64
    var name: String
    
}


struct Budget {
    var total: Double
    var categories: [String: BudgetDetails] // Category name to budget mapping
    var spent: [String: Double] // Category name to spent amount mapping
}

struct BudgetDetails: Codable{
    var limit: Double
      var timeFrame: BudgetTimeFrame
      var startDate: Date
      var endDate: Date
}

enum BudgetTimeFrame: String, Codable {
    case week, month, total
}


