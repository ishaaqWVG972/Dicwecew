//
//  DataScanVC.swift
//  DissoApp
//
//  Created by Ishaaq Ahmed on 13/02/2024.
//  Copyright © 2024 Ishaaq. All rights reserved.
//

import SwiftUI
import VisionKit

struct DataScannerVC: UIViewControllerRepresentable {
    @Binding var scannedText: String
    @Binding var liveScan: Bool
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let viewController = DataScannerViewController(recognizedDataTypes: [.text()],
                                                       qualityLevel: .balanced,
                                                       isHighlightingEnabled: true)
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if liveScan {
            try? uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: DataScannerVC
        init(parent: DataScannerVC) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .text(let text):
                parent.scannedText = text.transcript
                parent.liveScan = false
            default:
                break
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}
