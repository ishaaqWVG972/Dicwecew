



import SwiftUI

struct LoginView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingRegistration = false
    @State private var loginError: String = ""

    var body: some View {
        VStack {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            
            if !loginError.isEmpty {
                Text(loginError).foregroundColor(.red)
            }

            Button("Login") {
                loginUser()
            }

            Button("Register") {
                showingRegistration = true
            }
            .sheet(isPresented: $showingRegistration) {
                RegistrationView(isUserLoggedIn: $isUserLoggedIn)
            }
        }
    }

    private func loginUser() {
         let hashedPassword = password.data(using: .utf8)?.base64EncodedString() ?? ""
         do {
             if let userId = try DatabaseManager.shared.authenticateUserAndGetUserId(email: email, password: hashedPassword) {
                 // Storing user ID and setting logged-in status
                 KeychainManager.shared.storeUserId(userId)
                 KeychainManager.shared.setLoggedInStatus(true)
                 
                 DispatchQueue.main.async {
                     self.isUserLoggedIn = true
                     print("Login successful, user ID stored in Keychain.")
                 }
             } else {
                 loginError = "Invalid credentials"
             }
         } catch {
             loginError = "Login error: \(error.localizedDescription)"
         }
     }
 }


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isUserLoggedIn: .constant(false))
    }
}
