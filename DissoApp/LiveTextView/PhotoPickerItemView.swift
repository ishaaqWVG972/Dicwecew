//import SwiftUI
//import UIKit
//
//struct PhotoPickerItemView: UIViewControllerRepresentable {
//    var image: UIImage?
//
//    func makeUIViewController(context: Context) -> UIViewController {
//        let viewController = UIViewController()
//        viewController.view.backgroundColor = .white
//        
//        if let uiImage = image {
//            let imageView = UIImageView(image: uiImage)
//            imageView.contentMode = .scaleAspectFit
//            imageView.isUserInteractionEnabled = true // Enable user interaction
//            imageView.frame = viewController.view.bounds
//            viewController.view.addSubview(imageView)
//        }
//        
//        return viewController
//    }
//    
//    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
//        // Update the UI if necessary
//    }
//}
