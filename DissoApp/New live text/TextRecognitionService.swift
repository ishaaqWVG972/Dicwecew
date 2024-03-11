import Foundation

//struct ReceiptItem {
//    var name: String
//    var price: String
//}
//
//func parseReceiptText(_ text: String) -> [ReceiptItem] {
//    let lines = text.components(separatedBy: "\n")
//    var items: [ReceiptItem] = []
//    
//    var currentItemName: String = ""
//    for line in lines {
//        if line.matchesRegex("^\\$\\d+(\\.\\d{2})?$") { // Example regex for price in USD
//            let item = ReceiptItem(name: currentItemName, price: line)
//            items.append(item)
//            currentItemName = "" // Reset for next item
//        } else {
//            // Assuming non-price lines are product names; this might need refinement.
//            if !currentItemName.isEmpty {
//                currentItemName += " " // Add space if appending to existing name
//            }
//            currentItemName += line
//        }
//    }
//    
//    return items
//}
//
//extension String {
//    func matchesRegex(_ regex: String) -> Bool {
//        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
//    }
//}

