//
//  DissoAppApp.swift
//  DissoApp
//
//  Created by Ishaaq Ahmed on 27/12/2023.
//

import SwiftUI

@main
struct DissoAppApp: App {
    
    init() {
         // Initialize the database manager
         _ = DatabaseManager.shared
     }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
