//
//  CategorySelectionView.swift
//  DissoApp
//
//  Created by Ishaaq Ahmed on 06/01/2024.
//  Copyright © 2024 Ishaaq. All rights reserved.
//

import SwiftUI

struct CategorySelectionView: View {
    @Binding var selectedCategoryId: Int64?
    @State private var categories = [Category]()
    @State private var showingCategoryCreation = false
    var onCategorySelected: (String) -> Void

    var body: some View {
        NavigationView {
            List(categories, id: \.id) { category in
                Button(category.name) {
                    selectedCategoryId = category.id
                    onCategorySelected(category.name)
                    // Close the modal view
                }
            }
            .navigationBarTitle("Select a Category", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                showingCategoryCreation = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showingCategoryCreation) {
                CategoryCreationView()
            }
        }
        .onAppear {
            print("CategorySelectionView appeared")
            fetchCategories()
        }
    }

    private func fetchCategories() {
        do {
            categories = try DatabaseManager.shared.fetchCategories()
        } catch {
            print("Error fetching categories: \(error)")
        }
    }

}

