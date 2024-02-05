import SwiftUI
import Foundation


struct CategoryCreationView: View {
    @State private var categoryName: String = ""
   
    @Environment(\.presentationMode) var presentationMode

  

    private func saveCategory() {
            do {
                try DatabaseManager.shared.addCategory(name: categoryName)
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Error saving category: \(error)")
            }
        }

    var body: some View {
        VStack {
            TextField("Category Name", text: $categoryName)
            .padding()

            Button("Save Category", action: saveCategory)
        }
        .padding()
    }
}


