//
//  LiveTextUIImageView.swift
//  DissoApp
//
//  Created by Ishaaq Ahmed on 13/02/2024.
//  Copyright © 2024 Ishaaq. All rights reserved.
//

import SwiftUI
import VisionKit

@MainActor
struct LiveTextUIImageView: UIViewRepresentable {
    var image: UIImage
    let analyzer = ImageAnalyzer()
    let interaction = ImageAnalysisInteraction()
    let imageView = ResizableImageView()
    func makeUIView(context: Context) -> UIImageView {
        imageView.image = image
        imageView.addInteraction(interaction)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        Task {
            do {
                let configuration = ImageAnalyzer.Configuration([.text])
                if let image = imageView.image {
                    let analysis = try await analyzer.analyze(image, configuration: configuration)
                    interaction.analysis = analysis
                    interaction.preferredInteractionTypes = .textSelection
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    
}

class ResizableImageView: UIImageView {
    override var intrinsicContentSize: CGSize {
        .zero
    }
}
