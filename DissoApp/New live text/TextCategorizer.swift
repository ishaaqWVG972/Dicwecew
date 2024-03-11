import Foundation

struct TextBlock {
    let text: String
    let rect: CGRect
}

struct CategorizedText {
    var companyNames: [String] = []
    var productNames: [String] = []
    var prices: [String] = []
}

class TextCategorizer {
    
    /// Categorizes an array of TextBlocks into company names, product names, and prices.
    func categorizeTextBlocks(_ textBlocks: [String]) -> CategorizedText {
        var categorizedText = CategorizedText()

        // Assuming textBlocks[0] contains product names and textBlocks[1] contains prices
        let productLines = textBlocks[0].split(separator: "\n").map(String.init)
        let priceLines = textBlocks[1].split(separator: "\n").map(String.init)

        // We'll pair the products and prices based on their line indices
        let pairCount = min(productLines.count, priceLines.count) // Take the lesser count to avoid out-of-bounds error
        for i in 0..<pairCount {
            let productName = productLines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            let price = priceLines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Append paired product name and price
            categorizedText.productNames.append(productName)
            categorizedText.prices.append(price)
        }
        
        return categorizedText
    }


    /// Determines if a given string represents a price.
    func isPrice(_ text: String) -> Bool {
        let pricePattern = "\\b\\d+\\.\\d{2}\\b" // Matches price format e.g., "10.99"
        if let regex = try? NSRegularExpression(pattern: pricePattern),
           let _ = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
            return true
        }
        return false
    }


    /// Determines if a given string is likely to be a company name.
    /// Placeholder for more sophisticated company name heuristic.
    private func isCompanyName(_ text: String) -> Bool {
        // Implement more specific logic as needed.
        // This could involve checking for specific keywords, formats, or positions on the receipt.
        return false
    }
}
