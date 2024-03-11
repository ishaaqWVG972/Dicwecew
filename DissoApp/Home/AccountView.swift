import SwiftUI

struct AccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var isUserLoggedIn: Bool
    @ObservedObject var viewModel: TransactionViewModel

    var body: some View {
        VStack {
            // Your view content
            Button("Log Out") {
                print("Logging out...")
                KeychainManager.shared.clearUserData()
                DispatchQueue.main.async {
                    self.isUserLoggedIn = false
                    self.presentationMode.wrappedValue.dismiss()
                    print("After setting isUserLoggedIn: \(self.isUserLoggedIn)")
                }
            }
        }
    }
}

