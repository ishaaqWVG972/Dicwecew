
import Foundation
import CoreGraphics
import UIKit

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

struct Product: Identifiable, Codable, Hashable {
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

struct TextSelectionRectangle: Identifiable, Codable {
    var id = UUID()
    var rect: CGRect
    var capturedImage: UIImage?
    
    // Your Codable conformance and custom encoding/decoding logic here
    
    enum CodingKeys: String, CodingKey {
        case id
        case rect
        // capturedImage is intentionally omitted from CodingKeys
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        
        // Assuming you're decoding rect as an array or similar - ensure this logic is correct
        let rectArray = try container.decode([CGFloat].self, forKey: .rect)
        rect = CGRect(x: rectArray[0], y: rectArray[1], width: rectArray[2], height: rectArray[3])
        
        // Since capturedImage is not Codable, explicitly initialize it here
        capturedImage = nil
    }


    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        
        // Encoding CGRect as an array of CGFloat
        // [x, y, width, height]
        let rectArray = [rect.origin.x, rect.origin.y, rect.width, rect.height]
        try container.encode(rectArray, forKey: .rect)
        
        // Since UIImage is not directly Codable and is omitted from CodingKeys,
        // there's no need to encode capturedImage here.
        // If you decide to encode it, you'll need to convert UIImage to Data first.
    }

}

extension TextSelectionRectangle {
    // Convenience initializer
    init(id: UUID = UUID(), rect: CGRect, capturedImage: UIImage? = nil) {
        self.id = id
        self.rect = rect
        self.capturedImage = capturedImage
    }
}


//struct TextBlock {
//    let text: String
//    let rect: CGRect
//}


