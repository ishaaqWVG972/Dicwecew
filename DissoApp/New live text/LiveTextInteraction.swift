//
//  LiveTextInteraction.swift
//  DissoApp
//
//  Created by Ishaaq Ahmed on 11/02/2024.
//  Copyright © 2024 Ishaaq. All rights reserved.
//

import UIKit
import SwiftUI
import VisionKit

@MainActor
struct LiveTextInteraction: UIViewRepresentable {
    var selectedImage: UIImage
    let imageView = LiveTextImageView()
    let analyzer = ImageAnalyzer()
    let interaction = ImageAnalysisInteraction()
    
    func makeUIView(context: Context) -> some UIView {
        imageView.image = selectedImage // Use the selected image directly
        
        imageView.addInteraction(interaction)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        Task {
            let configuration = ImageAnalyzer.Configuration([.text])
            do {
                if let image = imageView.image {
                    let analysis = try await analyzer.analyze(image, configuration: configuration)
                    interaction.analysis = analysis
                    interaction.preferredInteractionTypes = .textSelection
                }
            } catch {
                // Handle error…
            }
        }
    }
}

class LiveTextImageView: UIImageView {
    override var intrinsicContentSize: CGSize {
        return .zero // Allows you to customize the size in your SwiftUI view
    }
}

