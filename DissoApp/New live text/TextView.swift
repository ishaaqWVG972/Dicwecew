import SwiftUI
import PhotosUI
import VisionKit
struct TextView: View {
    @StateObject var imagePicker = ImagePicker()
    @State private var scannedText = ""
    @FocusState var focusState: Bool
    @State var liveScan = false
    @ObservedObject var viewModel: TransactionViewModel
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20 ) {
//                TextEditor(text: $scannedText)
//                    .frame(height: 300)
//                    .border(Color.gray)
//                    .focused($focusState)
                if DataScannerViewController.isSupported {
                    Button("Scan with Camera") {
                        liveScan.toggle()
                        focusState = false
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text("Does not support Live Text from camera scan.")
                }
                if ImageAnalyzer.isSupported {
                    PhotosPicker(selection: $imagePicker.imageSelection, matching: .images, photoLibrary: .shared()) {
                        Text("Select Image")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text("Does not support Live Text scanning from image.")
                }
                Spacer()
                
              
            }
            .padding()
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        focusState = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down.fill")
                    }
                }
            }
            .navigationTitle("Live Text")
            .sheet(isPresented: $liveScan) {
                LiveTextFromCameraScan(liveScan: $liveScan, scannedText: $scannedText)
            }
            .sheet(item: $imagePicker.imageToScan) { imageToScan in
                TextFromImageView(imageToScan: imageToScan.image, scannedText: $scannedText, viewModel: viewModel)
            }
        }
    }
}
