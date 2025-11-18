//
//  AGHClient.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import Foundation

@MainActor
class AGHClient {
    var status: AGHStatus?
    var stats: AGHStats?
    var errorMessage: String?

    private let baseURL: String
    private let username: String
    private let password: String

    init(host: String, port: Int, username: String, password: String) {
        self.baseURL = "http://\(host):\(port)"
        self.username = username
        self.password = password
    }

    // MARK: - Demo Mode

    private var isDemoMode: Bool {
        return username == "demo" && password == "testing"
    }

    private var mockStatus: AGHStatus {
        AGHStatus(
            protectionEnabled: status?.protectionEnabled ?? true,
            running: true,
            version: "v0.107.52",
            dnsAddresses: ["127.0.0.1:53", "[::1]:53"]
        )
    }

    private var mockStats: AGHStats {
        AGHStats(
            numDnsQueries: 5678,
            numBlockedFiltering: 1234,
            numReplacedSafebrowsing: 12,
            avgProcessingTime: 0.042
        )
    }
    
    // MARK: - API Methods

    func fetchStatus() async {
        if isDemoMode {
            self.status = mockStatus
            self.errorMessage = nil
            return
        }

        if let result: AGHStatus = await performRequest(endpoint: "/control/status") {
            self.status = result
        }
    }
    
    func fetchStats() async {
        if isDemoMode {
            self.stats = mockStats
            self.errorMessage = nil
            return
        }

        if let result: AGHStats = await performRequest(endpoint: "/control/stats") {
            self.stats = result
        }
    }
    
    func toggleProtection(enable: Bool) async {
        if isDemoMode {
            // Update status to reflect the toggle
            self.status = AGHStatus(
                protectionEnabled: enable,
                running: true,
                version: "v0.107.52",
                dnsAddresses: ["127.0.0.1:53", "[::1]:53"]
            )
            self.errorMessage = nil
            // Simulate the 0.5s delay like real API
            try? await Task.sleep(nanoseconds: 500_000_000)
            // Refresh status and stats
            await fetchStatus()
            await fetchStats()
            return
        }

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
                // Success - clear any previous errors
                self.errorMessage = nil
                // Small delay to let AdGuard Home process the change
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
    
    func testConnection() async -> (success: Bool, errorMessage: String?) {
        if isDemoMode {
            return (true, nil)
        }

        guard let url = URL(string: baseURL + "/control/status") else {
            return (false, "Invalid URL: \(baseURL)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        addAuthHeader(to: &request)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    return (true, nil)
                } else if httpResponse.statusCode == 401 {
                    return (false, "Invalid username or password")
                } else if httpResponse.statusCode == 429 {
                    return (false, "Too many failed attempts. AdGuard Home has temporarily blocked access.")
                } else {
                    return (false, "Server returned error: HTTP \(httpResponse.statusCode)")
                }
            } else {
                return (false, "Invalid response from server")
            }
        } catch let error as NSError {
            if error.code == NSURLErrorTimedOut {
                return (false, "Connection timed out. Check your host and port.")
            } else if error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorCannotConnectToHost {
                return (false, "Cannot reach server at \(baseURL). Check host and port.")
            } else {
                return (false, error.localizedDescription)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func performRequest<T: Codable>(endpoint: String, method: String = "GET", body: [String: Any]? = nil) async -> T? {
        guard let url = URL(string: baseURL + endpoint) else {
            self.errorMessage = "Invalid URL"
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

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                self.errorMessage = "Invalid response"
                return nil
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                self.errorMessage = "HTTP \(httpResponse.statusCode)"
                return nil
            }

            let decoded = try JSONDecoder().decode(T.self, from: data)
            self.errorMessage = nil
            return decoded

        } catch {
            self.errorMessage = error.localizedDescription
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
