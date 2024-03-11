//
//  LiveTextFromCameraScan.swift
//  DissoApp
//
//  Created by Ishaaq Ahmed on 13/02/2024.
//  Copyright © 2024 Ishaaq. All rights reserved.
//

import SwiftUI

struct LiveTextFromCameraScan: View {
    @Environment(\.dismiss) var dismiss
    @Binding var liveScan: Bool
    @Binding var scannedText: String
    var body: some View {
        NavigationStack {
            VStack {
                DataScannerVC(scannedText: $scannedText, liveScan: $liveScan)
                Text("Capture Text")
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Capture Text")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LiveTextFromCameraScan_Previews: PreviewProvider {
    static var previews: some View {
        LiveTextFromCameraScan(liveScan: .constant(false), scannedText: .constant(""))
    }
}
