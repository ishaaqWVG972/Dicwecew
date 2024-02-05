//
//  CategoryEditView.swift
//  DissoApp
//
//  Created by Ishaaq Ahmed on 06/01/2024.
//  Copyright © 2024 Ishaaq. All rights reserved.
//

import SwiftUI

struct CategoryEditView: View {
    @Environment(\.presentationMode) var presentationMode
    var category: Category
    var onDismiss: () -> Void
    @State private var categoryName: String

    init(category: Category, onDismiss: @escaping () -> Void) {
        self.category = category
        self._categoryName = State(initialValue: category.name)
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Category Name", text: $categoryName)
                Button("Save") {
                    saveCategory()
                }
            }
            .navigationBarTitle("Edit Category", displayMode: .inline)
        }
    }

    private func saveCategory() {
        do {
            try DatabaseManager.shared.updateCategory(id: category.id, newName: categoryName)
            presentationMode.wrappedValue.dismiss()
            onDismiss()
        } catch {
            print("Error updating category: \(error)")
        }
    }
}

