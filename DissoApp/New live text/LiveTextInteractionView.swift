//
//  LiveTextInteractionView.swift
//  DissoApp
//
//  Created by Ishaaq Ahmed on 11/02/2024.
//  Copyright © 2024 Ishaaq. All rights reserved.
//

import SwiftUI

struct LiveTextInteractionView: View {
    var selectedImage: UIImage
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: TransactionViewModel
    @State private var showingFormView = false

    var body: some View {
        NavigationView {
            VStack {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()

                Text("Highlight and copy the text you need.")
                    .padding()
            }
            .navigationTitle("Highlight & Copy Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continue") {
                        showingFormView = true
                    }
                }
            }
            .sheet(isPresented: $showingFormView) {
                // Pass only the viewModel to FormView since it doesn't take selectedImage as a parameter
                FormView(viewModel: viewModel)
            }

        }
    }
}


//    
//

//import SwiftUI
//import UIKit
//
//struct LiveTextInteractionView: View {
//    var selectedImage: UIImage
//    @Environment(\.presentationMode) var presentationMode
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                Spacer()
//                LiveTextView(image: selectedImage)
//                    .scaledToFit()
//                    .padding()
//                Spacer()
//            }
//            .navigationBarItems(
//                leading: Button("Cancel") {
//                    presentationMode.wrappedValue.dismiss()
//                }
//            )
//        }
//    }
//}
//
//struct LiveTextView: UIViewRepresentable {
//    var image: UIImage
//
//    func makeUIView(context: Context) -> UIImageView {
//        let imageView = UIImageView(image: image)
//        imageView.contentMode = .scaleAspectFit
//        imageView.isUserInteractionEnabled = true // Enable user interaction
//        // No need to add UITextInteraction, system handles Live Text
//        return imageView
//    }
//
//    func updateUIView(_ uiView: UIImageView, context: Context) {
//        // Update the image if needed
//        uiView.image = image
//    }
//}
//
//struct LiveTextInteractionView_Previews: PreviewProvider {
//    static var previews: some View {
//        LiveTextInteractionView(selectedImage: UIImage(systemName: "photo") ?? UIImage())
//    }
//}
