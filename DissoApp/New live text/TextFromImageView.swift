//
//  TextFromImageView.swift
//  DissoApp
//
//  Created by Ishaaq Ahmed on 13/02/2024.
//  Copyright © 2024 Ishaaq. All rights reserved.
//

import SwiftUI

struct TextFromImageView: View {
    @Environment(\.dismiss) var dismiss
    private let pastboard = UIPasteboard.general
    let imageToScan: UIImage
    @Binding var scannedText: String
    
    @State private var currentPastboard = ""
    @State private var showingFormView = false
    @ObservedObject var viewModel: TransactionViewModel

    
    var body: some View {
        NavigationStack {
            VStack {
                LiveTextUIImageView(image: imageToScan)
//                Text("Select some text and copy it")
//                Button("Dismiss") {
//                    if let string = pastboard.string {
//                        if !string.isEmpty {
//                            scannedText = string
//                        }
//                    }
//                    dismiss()
//                }
//                
                Button("Continue") {
                    showingFormView = true
                }
                .sheet(isPresented: $showingFormView) {
                    FormView( viewModel: viewModel)
                }

                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Copy Text")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                pastboard.string = ""
            }
        }
    }
}

struct TextFromImageView_Previews: PreviewProvider {
    static var previews: some View {
        // Create an instance of your view model here
        let viewModel = TransactionViewModel()
        // Now, pass this instance to your TextFromImageView
        TextFromImageView(imageToScan: UIImage(), scannedText: .constant(""), viewModel: viewModel)
    }
}

