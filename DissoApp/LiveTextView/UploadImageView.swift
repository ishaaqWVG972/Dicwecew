//import SwiftUI
//
//struct UploadImageView: View {
//    @State private var showImagePicker: Bool = false
//    @State private var showCamera: Bool = false
//    @State private var image: UIImage?
//    @State private var isShowingImageViewer: Bool = false
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                Button("Take Image") {
//                    self.showCamera = true // This will show the camera interface
//                }
//                .padding()
//                .background(Color.gray)
//                .foregroundColor(.white)
//                .cornerRadius(8)
//                
//                Button("Upload Image") {
//                    self.showImagePicker = true // This will show the photo library
//                }
//                .padding()
//                .background(Color.gray)
//                .foregroundColor(.white)
//                .cornerRadius(8)
//                
//                NavigationLink(destination: ImageViewer(image: image ?? UIImage()), isActive: $isShowingImageViewer) {
//                    EmptyView()
//                }
//            }
//            .sheet(isPresented: $showCamera, onDismiss: {
//                if image != nil {
//                    isShowingImageViewer = true
//                }
//            }) {
//                ImagePicker(sourceType: .camera, selectedImage: $image)
//            }
//            .sheet(isPresented: $showImagePicker, onDismiss: {
//                if image != nil {
//                    isShowingImageViewer = true
//                }
//            }) {
//                ImagePicker(sourceType: .photoLibrary, selectedImage: $image)
//            }
//        }
//        .navigationViewStyle(StackNavigationViewStyle())
//    }
//}
//    
//    
//    struct ImagePicker: UIViewControllerRepresentable {
//        var sourceType: UIImagePickerController.SourceType
//        @Binding var selectedImage: UIImage?
//        
//        func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
//            let imagePicker = UIImagePickerController()
//            imagePicker.sourceType = sourceType
//            imagePicker.delegate = context.coordinator
//            return imagePicker
//        }
//        
//        func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
//            // No update action needed
//        }
//        
//        func makeCoordinator() -> Coordinator {
//            return Coordinator(self)
//        }
//        
//        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
//            var parent: ImagePicker
//            
//            init(_ parent: ImagePicker) {
//                self.parent = parent
//            }
//            
//            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
//                if let image = info[.originalImage] as? UIImage {
//                    parent.selectedImage = image
//                }
//                picker.dismiss(animated: true)
//            }
//            
//            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//                picker.dismiss(animated: true)
//            }
//        }
//    }
//    
//    struct UploadImageView_Previews: PreviewProvider {
//        static var previews: some View {
//            UploadImageView()
//        }
//    }
//



//import SwiftUI
//import PhotosUI
//
//struct UploadImageView: View {
//    @State private var imageSelection: PhotosPickerItem? // Holds the selection from PhotosPicker
//    @State private var pickedImage: UIImage? // The image that will be analyzed for live text
//    @State private var isShowingImageViewer = false // Controls the navigation to the ImageViewer
//
//    var body: some View {
//        VStack {
//            // Button to open the PhotosPicker
//            PhotosPicker(
//                selection: $imageSelection,
//                matching: .images,
//                photoLibrary: .shared()) {
//                    Label("Select Image", systemImage: "photo")
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                }
//                .onChange(of: imageSelection) { newItem in
//                    // Load the selected image
//                    loadPickedImage(newItem: newItem)
//                }
//
//            // Navigate to the ImageViewer view when an image is picked
//            if let pickedImage = pickedImage {
//                NavigationLink(destination: ImageViewer(image: pickedImage), isActive: $isShowingImageViewer) {
//                    EmptyView()
//                }
//            }
//        }
//    }
//
//    private func loadPickedImage(newItem: PhotosPickerItem?) {
//        guard let item = newItem else { return }
//        if item.canLoadObject(ofClass: UIImage.self) {
//            item.loadObject(ofClass: UIImage.self) { image, error in
//                if let image = image as? UIImage {
//                    DispatchQueue.main.async {
//                        self.pickedImage = image
//                        self.isShowingImageViewer = true
//                    }
//                }
//            }
//        }
//    }
//}
//
////struct ImageViewer: View {
////    var image: UIImage
////
////    var body: some View {
////        Image(uiImage: image)
////            .resizable()
////            .scaledToFit()
////            .navigationTitle("Selected Image")
////            .toolbar {
////                // Optionally add actions here, like a button for initiating live text recognition
////            }
////    }
////}
//
//struct UploadImageView_Previews: PreviewProvider {
//    static var previews: some View {
//        UploadImageView()
//    }
//}
