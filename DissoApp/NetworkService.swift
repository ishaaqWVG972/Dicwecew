//
//  NetworkService.swift
//  DissoApp
//
//  Created by Ishaaq Ahmed on 27/12/2023.
//

import Foundation
import KeychainSwift

class NetworkService {
    static let shared = NetworkService()
    let baseURL = "http://192.168.1.150:8080" 
    let keychain = KeychainSwift()

    func registerUser(registrationData: UserRegistration, completion: @escaping (Result<User, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/users/register") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONEncoder().encode(registrationData)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else { return }
            do {
                 let user = try JSONDecoder().decode(User.self, from: data)
                 completion(.success(user))
             } catch {
                 completion(.failure(error))
             }
        }.resume()
    }
    
   

    func loginUser(email: String, password: String, completion: @escaping (Result<Token, Error>) -> Void) {
           guard let url = URL(string: "\(baseURL)/users/login") else {
               print("Invalid URL")
               return
           }
           var request = URLRequest(url: url)
           request.httpMethod = "POST"
           request.addValue("application/json", forHTTPHeaderField: "Content-Type")

           let loginInfo = ["email": email, "password": password]
           do {
               let jsonData = try JSONSerialization.data(withJSONObject: loginInfo)
               request.httpBody = jsonData
               print("Login request prepared.")
           } catch {
               print("JSON encoding error: \(error)")
               completion(.failure(error))
               return
           }

           URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
               guard let self = self else {
                   print("Self reference lost")
                   return
               }

               if let error = error {
                   print("Network error: \(error.localizedDescription)")
                   completion(.failure(error))
                   return
               }

               guard let data = data else {
                   print("No data received from server")
                   completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data from server"])))
                   return
               }

               do {
                   let tokenResponse = try JSONDecoder().decode(Token.self, from: data)
                   print("Token received: \(tokenResponse.value)")
                   self.keychain.set(tokenResponse.value, forKey: "userToken")
                   print("Token saved to keychain.")
                   completion(.success(tokenResponse))
               } catch {
                   print("Decoding error: \(error.localizedDescription)")
                   completion(.failure(error))
               }
           }.resume()
       }

    
    // Call this method to retrieve the token for authenticated requests
     func getAuthToken() -> String? {
         return keychain.get("userToken")
     }

     // Call this method to delete the token when logging out
     func deleteAuthToken() {
         keychain.delete("userToken")
     }
    
    
    func submitTransaction(_ transaction: Transaction, token: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/transactions") else {
            print("Invalid URL")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let transactionRequest = TransactionRequest(
                id: transaction.id,
                companyName: transaction.companyName,
                products: transaction.products,
                totalPrice: transaction.totalPrice,
                userSelectedDate: transaction.userSelectedDate
            )
            
            let jsonData = try JSONEncoder().encode(transactionRequest)
            request.httpBody = jsonData
        } catch {
            print("JSON encoding error: \(error)")
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network request error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                print("Server responded with status code: \(httpResponse.statusCode)")
                completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server responded with error"])))
                return
            }

            completion(.success(true))
        }.resume()
    }
    
    // NetworkService.swift

//     Add a method to fetch transactions
    func fetchTransactions(token: String, completion: @escaping (Result<[Transaction], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/user/transactions") else {
            print("Invalid URL for fetching transactions")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
                return
            }
            do {
                let transactions = try JSONDecoder().decode([Transaction].self, from: data)
                completion(.success(transactions))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }


 }
    
    

