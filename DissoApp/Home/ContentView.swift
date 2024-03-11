import SwiftUI

struct ContentView: View {
    @State private var isUserLoggedIn: Bool = KeychainManager.shared.getLoggedInStatus()
    @StateObject private var viewModel = TransactionViewModel()
    
        var body: some View {
            if isUserLoggedIn {
                MainView(isUserLoggedIn: $isUserLoggedIn, viewModel: viewModel)
            } else {
                LoginView(isUserLoggedIn: $isUserLoggedIn)
            }
        }
    }   



// For previewing ContentView
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
