
import SwiftUI
import VisionKit
import Vision


extension String {
    func matches(_ regex: String) -> Bool {
        self.range(of: regex, options: .regularExpression) != nil
    }
}


extension String {
    func containsDigit() -> Bool {
        return self.rangeOfCharacter(from: .decimalDigits) != nil
    }
}

extension CGRect {
    // Check if this bounding box is to the left of another
    func isToLeftOf(_ rect: CGRect) -> Bool {
        return self.maxX <= rect.minX
    }

    // Calculate horizontal distance to another bounding box
    func horizontalDistance(to rect: CGRect) -> CGFloat? {
        if self.isToLeftOf(rect) {
            return rect.minX - self.maxX
        }
        return nil
    }
}

struct ScanDocumentView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var recognizedText: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedText: $recognizedText, parent: self)
    }
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let documentViewController = VNDocumentCameraViewController()
        documentViewController.delegate = context.coordinator
        return documentViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // Nothing to do here
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var recognizedText: Binding<String>
        var parent: ScanDocumentView
        
        init(recognizedText: Binding<String>, parent: ScanDocumentView) {
            self.recognizedText = recognizedText
            self.parent = parent
            super.init()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let extractedImages = extractImages(from: scan)
            recognizeText(from: extractedImages)
        }
        
        fileprivate func extractImages(from scan: VNDocumentCameraScan) -> [CGImage] {
            var extractedImages = [CGImage]()
            for index in 0..<scan.pageCount {
                let extractedImage = scan.imageOfPage(at: index)
                guard let cgImage = extractedImage.cgImage else { continue }
                extractedImages.append(cgImage)
            }
            return extractedImages
        }
        
        fileprivate func recognizeText(from images: [CGImage]) {
            let recognizeTextRequest = VNRecognizeTextRequest { [weak self] request, error in
                guard let self = self else { return }
                if let error = error {
                    print("Text recognition error: \(error.localizedDescription)")
                    return
                }
                
                var recognizedTextArray: [String] = []
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    print("No text observations were found.")
                    return
                }
                
                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    // Custom logic to filter out unwanted details
                    if candidate.confidence > 0.8 && self.isValidText(candidate.string) {
                        recognizedTextArray.append(candidate.string)
                    }
                }
                
                DispatchQueue.main.async {
                    self.recognizedText.wrappedValue = recognizedTextArray.joined(separator: "\n")
                    self.parent.presentationMode.wrappedValue.dismiss()
                }
            }
            
            recognizeTextRequest.usesLanguageCorrection = true
            recognizeTextRequest.recognitionLevel = .accurate
            
            for image in images {
                let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try requestHandler.perform([recognizeTextRequest])
                } catch {
                    print("Failed to perform text recognition request: \(error)")
                }
            }
        }
        
        // Custom function to determine if a text should be included or not
        func isValidText(_ text: String) -> Bool {
            // Check against unwanted patterns first, such as postal codes or address formats
            let unwantedPatterns = ["\\d{5,}", "^[A-Za-z0-9]+\\s[A-Za-z0-9]+\\s\\d{2,4}$"] // Regex patterns for postal codes or addresses
            for pattern in unwantedPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern),
                   regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil {
                    return false // It's an unwanted pattern
                }
            }

            // Convert text to lowercased for case-insensitive comparison
            let lowercasedText = text.lowercased()

            // Define keywords that often appear in irrelevant sections of a receipt
            let unwantedKeywords = ["address", "www", "visit", "subtotal", "total", "tax", "change", "cash", "card", "sale", "server", "guest", "table", "tel", "thank you", "receipt", "transaction"]

            // Check if the text contains any unwanted keywords
            for keyword in unwantedKeywords {
                if lowercasedText.contains(keyword) {
                    return false
                }
            }

            // Check if the text is likely a price or product name
            // This regex matches prices (e.g., "10.99")
            let priceRegex = "\\b\\d+\\.\\d{2}\\b"
            if lowercasedText.matches(priceRegex) || (!text.containsDigit() && !text.isEmpty) {
                return true // It's likely a product name or price
            }

            return false // If none of the above, it's not valid
        }
        
        
        
        func processObservations(_ observations: [VNRecognizedTextObservation]) -> (companyName: String?, products: [Product]) {
            var companyName: String?
            var productCandidates: [VNRecognizedTextObservation] = []
            var priceCandidates: [VNRecognizedTextObservation] = []
            
            // Step 1: Filter observations and categorize them
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                
                // Filter out unwanted text based on content (e.g., regex for addresses or postcodes)
                if isValidText(topCandidate.string) {
                    // Assuming the top part of the receipt contains the company name and possibly other non-product text
                    // If no company name found yet, and observation is in the top half, consider it as company name
                    if companyName == nil && observation.boundingBox.minY > 0.5 {
                        companyName = topCandidate.string
                    } else {
                        // Further classify text as product name or price based on a simple heuristic (e.g., contains digits -> price)
                        if topCandidate.string.containsDigit() {
                            priceCandidates.append(observation)
                        } else {
                            productCandidates.append(observation)
                        }
                    }
                }
            }
            
            // Step 2: Match product names with prices
            var products: [Product] = []
            for priceObservation in priceCandidates {
                let priceBoundingBox = priceObservation.boundingBox
                var closestProductObservation: VNRecognizedTextObservation?
                var minDistance = CGFloat.greatestFiniteMagnitude
                
                // Find the closest product name to the left of each price
                for productObservation in productCandidates {
                    let productBoundingBox = productObservation.boundingBox
                    
                    // Check if product is to the left and relatively aligned horizontally
                    if productBoundingBox.isToLeftOf(priceBoundingBox),
                       let distance = productBoundingBox.horizontalDistance(to: priceBoundingBox),
                       distance < minDistance {
                        closestProductObservation = productObservation
                        minDistance = distance
                    }
                }
                
                if let productObservation = closestProductObservation,
                   let productName = productObservation.topCandidates(1).first?.string,
                   let priceString = priceObservation.topCandidates(1).first?.string,
                   let price = Double(priceString.filter("0123456789.".contains)) {
                    products.append(Product(id: UUID(), name: productName, price: price))
                }
            }
            
            return (companyName, products)
        }
        
        func processObservationsImproved(_ observations: [VNRecognizedTextObservation]) -> (companyName: String?, products: [Product]) {
            var companyName: String?
            var productCandidates: [VNRecognizedTextObservation] = []
            var priceCandidates: [VNRecognizedTextObservation] = []
            
            // Improved filtering and categorization logic
            observations.forEach { observation in
                guard let topCandidate = observation.topCandidates(1).first else { return }
                
                if isValidText(topCandidate.string) {
                    if observation.boundingBox.minY > 0.5 && companyName == nil {
                        // Assuming companyName is towards the top of the receipt
                        companyName = topCandidate.string
                    } else if topCandidate.string.containsDigit() && topCandidate.string.contains(".") {
                        // Heuristic: Price usually contains a period (.) for the decimal point
                        priceCandidates.append(observation)
                    } else {
                        // Remaining text considered as product candidates
                        productCandidates.append(observation)
                    }
                }
            }
            
            // Match products with prices based on spatial proximity
            let products = matchProductsToPrices(productCandidates: productCandidates, priceCandidates: priceCandidates)
            
            return (companyName, products)
        }
        
        private func matchProductsToPrices(productCandidates: [VNRecognizedTextObservation], priceCandidates: [VNRecognizedTextObservation]) -> [Product] {
            var products: [Product] = []
            
            for productObservation in productCandidates {
                guard let productName = productObservation.topCandidates(1).first?.string else { continue }
                var closestPrice: (observation: VNRecognizedTextObservation, distance: CGFloat) = (observation: productObservation, distance: CGFloat.greatestFiniteMagnitude)
                
                for priceObservation in priceCandidates {
                    let distance = calculateDistance(from: productObservation.boundingBox, to: priceObservation.boundingBox)
                    
                    if distance < closestPrice.distance {
                        closestPrice = (observation: priceObservation, distance: distance)
                    }
                }
                
                // Extract and parse the price
                if let priceString = closestPrice.observation.topCandidates(1).first?.string,
                   let price = Double(priceString.filter("0123456789.".contains)) {
                    products.append(Product(id: UUID(), name: productName, price: price))
                }
            }
            
            return products
        }
        private func calculateDistance(from rect1: CGRect, to rect2: CGRect) -> CGFloat {
            // Calculate a simple Euclidean distance between the centers of two rectangles
            let center1 = CGPoint(x: rect1.midX, y: rect1.midY)
            let center2 = CGPoint(x: rect2.midX, y: rect2.midY)
            return CGFloat(sqrt(pow(center2.x - center1.x, 2) + pow(center2.y - center1.y, 2)))
            
            
            
            
            
        }
    }
    
    
    
    struct ScanDocumentView_Previews: PreviewProvider {
        static var previews: some View {
            ScanDocumentView(recognizedText: .constant(""))
        }
    }
}


//import SwiftUI
//import VisionKit
//import Vision
//
//import SwiftUI
//import VisionKit
//
//struct LiveTextImagePickerView: View {
//    @State private var showingImagePicker = false
//    @State private var inputImage: UIImage?
//    @State private var analyzedImage: UIImage?
//    
//    var body: some View {
//        VStack {
//            if let inputImage = inputImage {
//                LiveTextUIImageView(image: inputImage)
//                    .frame(height: 300)
//                    .padding()
//            } else {
//                Button("Upload Image") {
//                    showingImagePicker = true
//                }
//                .padding()
//                .background(Color.blue)
//                .foregroundColor(.white)
//                .clipShape(RoundedRectangle(cornerRadius: 10))
//            }
//        }
//        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
//            PhotoPicker(selectedImage: $inputImage)
//        }
//    }
//    
//    func loadImage() {
//        guard let inputImage = inputImage else { return }
//        analyzedImage = inputImage // Here you might want to do additional processing
//    }
//}
//
//@MainActor
//struct LiveTextUIImageView: UIViewRepresentable {
//    var image: UIImage
//    let analyzer = ImageAnalyzer()
//    let interaction = ImageAnalysisInteraction()
//    let imageView = ResizableImageView()
//    
//    func makeUIView(context: Context) -> UIImageView {
//        imageView.image = image
//        imageView.addInteraction(interaction)
//        imageView.contentMode = .scaleAspectFit
//        return imageView
//    }
//    
//    func updateUIView(_ uiView: UIImageView, context: Context) {
//        Task {
//            do {
//                let configuration = ImageAnalyzer.Configuration([.text])
//                if let image = imageView.image {
//                    let analysis = try await analyzer.analyze(image, configuration: configuration)
//                    interaction.analysis = analysis
//                    interaction.preferredInteractionTypes = .textSelection
//                }
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
//    }
//}
//
//class ResizableImageView: UIImageView {
//    override var intrinsicContentSize: CGSize {
//        return image?.size ?? .zero
//    }
//}
