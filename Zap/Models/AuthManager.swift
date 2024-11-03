//
//  AuthManager.swift
//  Zap
//
//  Created by Zigao Wang on 11/3/24.
//

import Foundation

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    let baseURL = URL(string: "https://auth.api.zap-notes.com")!
    
    private init() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    // Models
    struct User: Codable {
        let id: String
        let email: String
    }
    
    struct AuthResponse: Codable {
        let token: String
        let user: User
    }
    
    struct ErrorResponse: Codable {
        let message: String
    }
    
    enum AuthError: LocalizedError {
        case invalidCredentials
        case registrationFailed
        case serverError(String)
        case networkError
        case invalidResponse
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Invalid email or password"
            case .registrationFailed:
                return "Registration failed. Please try again"
            case .serverError(let message):
                return message
            case .networkError:
                return "Network error. Please check your connection"
            case .invalidResponse:
                return "Invalid server response"
            }
        }
    }
    
    func register(email: String, password: String) async throws {
        let registerData = ["email": email, "password": password]
        
        var request = URLRequest(url: baseURL.appendingPathComponent("/auth/register"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(registerData)
            request.httpBody = jsonData
            
            print("Request URL:", request.url?.absoluteString ?? "")
            print("Request Body:", String(data: jsonData, encoding: .utf8) ?? "")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }
            
            print("Response Status Code:", httpResponse.statusCode)
            print("Response Headers:", httpResponse.allHeaderFields)
            print("Response Data:", String(data: data, encoding: .utf8) ?? "No data")
            
            if httpResponse.statusCode == 404 {
                throw AuthError.serverError("Endpoint not found. Please check server configuration.")
            }
            
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AuthError.serverError(errorResponse.message)
                } else {
                    throw AuthError.registrationFailed
                }
            }
            
            let decoder = JSONDecoder()
            do {
                let authResponse = try decoder.decode(AuthResponse.self, from: data)
                await MainActor.run {
                    self.currentUser = authResponse.user
                    self.isAuthenticated = true
                    if let userData = try? JSONEncoder().encode(authResponse.user) {
                        UserDefaults.standard.set(userData, forKey: "currentUser")
                    }
                }
            } catch {
                print("Decoding error:", error)
                throw AuthError.invalidResponse
            }
        } catch {
            print("Registration error:", error)
            if let authError = error as? AuthError {
                throw authError
            } else {
                throw AuthError.serverError(error.localizedDescription)
            }
        }
    }
    
    func login(email: String, password: String) async throws {
        let loginData = ["email": email, "password": password]
        
        var request = URLRequest(url: baseURL.appendingPathComponent("/auth/login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(loginData)
            request.httpBody = jsonData
            
            print("Request URL:", request.url?.absoluteString ?? "")
            print("Request Body:", String(data: jsonData, encoding: .utf8) ?? "")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }
            
            print("Response Status Code:", httpResponse.statusCode)
            print("Response Headers:", httpResponse.allHeaderFields)
            print("Response Data:", String(data: data, encoding: .utf8) ?? "No data")
            
            if httpResponse.statusCode == 404 {
                throw AuthError.serverError("Endpoint not found. Please check server configuration.")
            }
            
            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AuthError.serverError(errorResponse.message)
                } else {
                    throw AuthError.invalidCredentials
                }
            }
            
            let decoder = JSONDecoder()
            do {
                let authResponse = try decoder.decode(AuthResponse.self, from: data)
                await MainActor.run {
                    self.currentUser = authResponse.user
                    self.isAuthenticated = true
                    if let userData = try? JSONEncoder().encode(authResponse.user) {
                        UserDefaults.standard.set(userData, forKey: "currentUser")
                    }
                }
            } catch {
                print("Decoding error:", error)
                throw AuthError.invalidResponse
            }
        } catch {
            print("Login error:", error)
            if let authError = error as? AuthError {
                throw authError
            } else {
                throw AuthError.serverError(error.localizedDescription)
            }
        }
    }
    
    func logout() {
        self.currentUser = nil
        self.isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
}
