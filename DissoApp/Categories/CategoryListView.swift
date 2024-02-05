import SwiftUI
import Foundation

struct CategoryListView: View {
    @State private var showingCategoryCreation = false
    @State private var categories = [Category]()
    @State private var editingCategoryId: Int64? // ID of the category being edited
    @State private var showingEditOptions = false
    @State private var showingEditModal = false
    @State private var categoryToEdit: Category?
    
    
    
    
    private func fetchCategories() {
        do {
            categories = try DatabaseManager.shared.fetchCategories()
        } catch {
            print("Error fetching categories: \(error)")
        }
    }
    
    var body: some View {
        NavigationView {
            List(categories, id: \.id) { category in
                HStack {
                    Text(category.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(action: {
                        editingCategoryId = category.id
                        showingEditOptions = true
                    }) {
                        Image(systemName: "ellipsis")
                            .imageScale(.large)
                    }
                    .actionSheet(isPresented: $showingEditOptions) {
                        ActionSheet(
                            title: Text("Edit Category"),
                            buttons: [
                                .default(Text("Edit")) { showEditCategoryView(category) },
                                .destructive(Text("Delete")) { deleteCategory(category) },
                                .cancel()
                            ]
                        )
                    }
                    .sheet(isPresented: $showingEditModal) {
                                    if let category = categoryToEdit {
                                        CategoryEditView(category: category, onDismiss: fetchCategories)
                                    }
                                }
                }
            }
            .navigationBarItems(trailing: Button("Add Category") {
                showingCategoryCreation = true
            })
            .sheet(isPresented: $showingCategoryCreation, onDismiss: fetchCategories) {
                CategoryCreationView()
            }
            .onAppear(perform: fetchCategories)
        }
    }
    
    
    private func showEditCategoryView(_ category: Category) {
        categoryToEdit = category
        showingEditModal = true
    }
    
    private func deleteCategory(_ category: Category) {
        do {
            try DatabaseManager.shared.deleteCategory(id: category.id)
            fetchCategories() // Refresh categories list
        } catch {
            print("Error deleting category: \(error)")
        }
    }
}

