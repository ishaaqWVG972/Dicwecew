

import SwiftUI

struct RegistrationView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var registrationError: String = ""

    var body: some View {
        VStack {
            TextField("Name", text: $name)
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            if !registrationError.isEmpty {
                Text(registrationError).foregroundColor(.red)
            }
            Button("Sign Up") {
                registerUser()
            }
        }
    }

    private func registerUser() {
        // Simple password hash (replace with a secure method like BCrypt)
        let passwordHash = password.data(using: .utf8)?.base64EncodedString() ?? ""

        do {
            try DatabaseManager.shared.registerUser(name: name, email: email, passwordHash: passwordHash)
            print("Registration successful, user: \(name)")
            DispatchQueue.main.async {
                self.isUserLoggedIn = true
            }
        } catch {
            print("Registration error: \(error)")
            DispatchQueue.main.async {
                self.registrationError = "Failed to register: \(error.localizedDescription)"
            }
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView(isUserLoggedIn: .constant(false))
    }
}
