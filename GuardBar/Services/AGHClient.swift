//
//  AGHClient.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import Foundation
import Combine

class AGHClient: ObservableObject {
    @Published var status: AGHStatus?
    @Published var stats: AGHStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL: String
    private let username: String
    private let password: String
    
    init(host: String, port: Int, username: String, password: String) {
        self.baseURL = "http://\(host):\(port)"
        self.username = username
        self.password = password
    }
    
    // MARK: - API Methods
    
    @MainActor
    func fetchStatus() async {
        if let result: AGHStatus = await performRequest(endpoint: "/control/status") {
            self.status = result
        }
    }
    
    @MainActor
    func fetchStats() async {
        if let result: AGHStats = await performRequest(endpoint: "/control/stats") {
            self.stats = result
        }
    }
    
    @MainActor
    func toggleProtection(enable: Bool) async {
        let body = ["protection_enabled": enable]
        
        // Use a simpler inline request for toggle since we don't need response parsing
        guard let url = URL(string: baseURL + "/control/dns_config") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(to: &request)
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                // Success - small delay to let AdGuard Home process the change
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                // Refresh status after toggle
                await fetchStatus()
                await fetchStats()
            } else {
                self.errorMessage = "Failed to toggle protection"
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func testConnection() async -> Bool {
        await withCheckedContinuation { continuation in
            Task {
                let url = URL(string: baseURL + "/control/status")!
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                self.addAuthHeader(to: &request)
                
                do {
                    let (_, response) = try await URLSession.shared.data(for: request)
                    if let httpResponse = response as? HTTPURLResponse {
                        continuation.resume(returning: (200...299).contains(httpResponse.statusCode))
                    } else {
                        continuation.resume(returning: false)
                    }
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func performRequest<T: Codable>(endpoint: String, method: String = "GET", body: [String: Any]? = nil) async -> T? {
        guard let url = URL(string: baseURL + endpoint) else {
            await MainActor.run {
                self.errorMessage = "Invalid URL"
                self.isLoading = false
            }
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        addAuthHeader(to: &request)
        
        // Add body if present
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    self.errorMessage = "Invalid response"
                    self.isLoading = false
                }
                return nil
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                await MainActor.run {
                    self.errorMessage = "HTTP \(httpResponse.statusCode)"
                    self.isLoading = false
                }
                return nil
            }
            
            let decoded = try JSONDecoder().decode(T.self, from: data)
            await MainActor.run {
                self.errorMessage = nil
                self.isLoading = false
            }
            return decoded
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return nil
        }
    }
    
    private func addAuthHeader(to request: inout URLRequest) {
        let credentials = "\(username):\(password)"
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }
    }
}
