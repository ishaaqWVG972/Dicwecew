//import SwiftUI
//import PhotosUI
//
//// This structure may not be necessary with direct PhotosPicker usage in SwiftUI.
//// Keeping it for backward compatibility or specific use cases.
//struct PhotoPickerView: UIViewControllerRepresentable {
//    typealias PHPickerResultHandler = (Result<UIImage, Error>) -> Void
//    var completionHandler: PHPickerResultHandler
//
//    func makeUIViewController(context: Context) -> PHPickerViewController {
//        var config = PHPickerConfiguration()
//        config.filter = .images
//        config.selectionLimit = 1
//        let picker = PHPickerViewController(configuration: config)
//        picker.delegate = context.coordinator
//        return picker
//    }
//
//    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
//        // No update action needed here.
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self, completionHandler: completionHandler)
//    }
//
//    class Coordinator: NSObject, PHPickerViewControllerDelegate {
//        var parent: PhotoPickerView
//        var completionHandler: PHPickerResultHandler
//
//        init(_ parent: PhotoPickerView, completionHandler: @escaping PHPickerResultHandler) {
//            self.parent = parent
//            self.completionHandler = completionHandler
//        }
//
//        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//            picker.dismiss(animated: true)
//
//            guard let item = results.first else {
//                completionHandler(.failure(URLError(.cannotLoadFromNetwork)))
//                return
//            }
//
//            if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
//                item.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
//                    DispatchQueue.main.async {
//                        if let image = image as? UIImage {
//                            self.completionHandler(.success(image))
//                        } else if let error = error {
//                            self.completionHandler(.failure(error))
//                        } else {
//                            self.completionHandler(.failure(URLError(.cannotParseResponse)))
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
