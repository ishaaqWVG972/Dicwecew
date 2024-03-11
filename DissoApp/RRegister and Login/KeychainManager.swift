import Foundation
import KeychainSwift

class KeychainManager {
    static let shared = KeychainManager()
    private let keychain = KeychainSwift()
    private let loggedInStatusKey = "isLoggedIn"
    private let userIdKey = "userId"

    // Store the user ID in the keychain
    func storeUserId(_ id: Int64) {
        keychain.set(String(id), forKey: userIdKey)
        print("User ID stored in Keychain: \(id)")
    }

    // Retrieve the user ID from the keychain
    func getUserId() -> Int64? {
        if let idString = keychain.get(userIdKey), let id = Int64(idString) {
            return id
            print("Retrieved User ID from Keychain: \(id)")
        }
        print("User ID not found in Keychain.")
        return nil
    }

    // Set the user's logged-in status
    func setLoggedInStatus(_ isLoggedIn: Bool) {
        keychain.set(isLoggedIn, forKey: loggedInStatusKey)
    }

    // Retrieve the user's logged-in status
    func getLoggedInStatus() -> Bool {
        return keychain.getBool(loggedInStatusKey) ?? false
    }

    // Clear all user data from the keychain (useful for log out)
    func clearUserData() {
          keychain.delete(loggedInStatusKey)
          keychain.delete(userIdKey)
          setLoggedInStatus(false) // Explicitly set logged-in status to false
          print("User data cleared from Keychain")
      }


    // Convenience method to check if a user is currently logged in
    func isLoggedIn() -> Bool {
        return getLoggedInStatus() && getUserId() != nil
    }

    // Add more methods as needed for other user data...
}
