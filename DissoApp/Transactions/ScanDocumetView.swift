
import SwiftUI
import VisionKit
import Vision

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
                    recognizedTextArray.append(candidate.string)
                }

                DispatchQueue.main.async {
                    self.recognizedText.wrappedValue = recognizedTextArray.joined(separator: "\n")
                    self.parent.presentationMode.wrappedValue.dismiss()
                }
            }

            recognizeTextRequest.recognitionLevel = .accurate
            recognizeTextRequest.usesLanguageCorrection = true

            for image in images {
                let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try requestHandler.perform([recognizeTextRequest])
                } catch {
                    print("Failed to perform text recognition request: \(error)")
                }
            }
        }
    }
}

// Example usage in a preview
struct ScanDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        ScanDocumentView(recognizedText: .constant(""))
    }
}
