import SwiftUI

struct AccountView: View {
    @Binding var isUserLoggedIn: Bool
    @StateObject var viewModel: TransactionViewModel
    
    var body: some View {
        VStack {
            Text("Account Settings")
            // Add other account-related settings here

            Spacer()
            
            Button("Log Out") {
                isUserLoggedIn = false
                KeychainManager.shared.setLoggedInStatus(false)
            }
            .padding()
        }
    }
}
