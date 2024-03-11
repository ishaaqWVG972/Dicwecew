//import SwiftUI
//
//struct ImageViewer: View {
//    @Environment(\.presentationMode) var presentationMode
//    var image: UIImage
//    @State private var showingTagView = false
//
//    var body: some View {
//        VStack {
//            Image(uiImage: image)
//                .resizable()
//                .scaledToFit()
//            Spacer()
//        }
//        .edgesIgnoringSafeArea(.all)
//        .navigationBarTitle("Image Viewer", displayMode: .inline)
//        .navigationBarItems(trailing: Button("Add Tag") {
//            showingTagView = true
//        })
//        .sheet(isPresented: $showingTagView) {
//            // Replace with your actual tag adding view
//            Text("Tagging view goes here")
//        }
//    }
//}
