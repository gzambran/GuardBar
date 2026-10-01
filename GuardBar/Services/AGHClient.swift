//
//  AGHClient.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import Foundation

/// The AdGuard Home operations the app depends on
protocol AGHService: AnyObject {
    func fetchStatus() async throws -> AGHStatus
    func fetchStats() async throws -> AGHStats
    /// Turns protection on or off. A `duration` pauses protection and AdGuard Home re-enables it itself.
    func setProtection(enabled: Bool, duration: TimeInterval?) async throws
}

/// Everything needed to reach an AdGuard Home instance
struct AGHConnection: Equatable {
    let host: String
    let port: Int
    let username: String
    let password: String

    var isDemo: Bool {
        username == "demo" && password == "testing"
    }

    /// Base URL for the server. `host` may include an `http://` or `https://` prefix; plain hosts use HTTP.
    var baseURL: URL? {
        var address = host.trimmingCharacters(in: .whitespacesAndNewlines)
        while address.hasSuffix("/") { address.removeLast() }

        var components = URLComponents()
        components.scheme = "http"
        for scheme in ["http", "https"] where address.lowercased().hasPrefix("\(scheme)://") {
            components.scheme = scheme
            address = String(address.dropFirst(scheme.count + 3))
        }

        // IPv6 literals need brackets in a URL
        if address.contains(":") && !address.hasPrefix("[") {
            address = "[\(address)]"
        }

        guard !address.isEmpty else { return nil }
        components.host = address
        components.port = port
        return components.url
    }

    func makeService() -> AGHService {
        isDemo ? DemoAGHClient() : AGHClient(connection: self)
    }
}

enum AGHError: LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited
    case http(Int)
    case timedOut
    case cannotReach(String)
    case network(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server address"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Invalid username or password"
        case .rateLimited:
            return "Too many failed attempts. AdGuard Home has temporarily blocked access."
        case .http(let code):
            return "Server returned error: HTTP \(code)"
        case .timedOut:
            return "Connection timed out. Check your host and port."
        case .cannotReach(let address):
            return "Cannot reach server at \(address). Check host and port."
        case .network(let message):
            return message
        }
    }
}

final class AGHClient: AGHService {
    typealias Transport = (URLRequest) async throws -> (Data, URLResponse)

    private let connection: AGHConnection
    private let transport: Transport
    private let timeout: TimeInterval = 10

    init(connection: AGHConnection, transport: @escaping Transport = { try await URLSession.shared.data(for: $0) }) {
        self.connection = connection
        self.transport = transport
    }

    // MARK: - API Methods

    func fetchStatus() async throws -> AGHStatus {
        let data = try await send(path: "/control/status")
        return try decode(AGHStatus.self, from: data)
    }

    func fetchStats() async throws -> AGHStats {
        let data = try await send(path: "/control/stats")
        return try decode(AGHStats.self, from: data)
    }

    func setProtection(enabled: Bool, duration: TimeInterval?) async throws {
        var body: [String: Any] = ["enabled": enabled]
        if !enabled, let duration {
            body["duration"] = Int((duration * 1000).rounded())
        }
        _ = try await send(path: "/control/protection", method: "POST", body: body)
    }

    // MARK: - Private Helpers

    private func send(path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> Data {
        guard let baseURL = connection.baseURL,
              let url = URL(string: path, relativeTo: baseURL) else {
            throw AGHError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout
        let credentials = Data("\(connection.username):\(connection.password)".utf8).base64EncodedString()
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport(request)
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw AGHError.timedOut
            case .cannotFindHost, .cannotConnectToHost:
                throw AGHError.cannotReach(baseURL.absoluteString)
            default:
                throw AGHError.network(error.localizedDescription)
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AGHError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401, 403:
            throw AGHError.unauthorized
        case 429:
            throw AGHError.rateLimited
        default:
            throw AGHError.http(httpResponse.statusCode)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw AGHError.invalidResponse
        }
    }
}

// MARK: - Demo Mode

/// In-memory stand-in for AdGuard Home, used with the demo credentials
final class DemoAGHClient: AGHService {
    private var protectionEnabled = true
    private var resumeAt: Date?

    func fetchStatus() async throws -> AGHStatus {
        if let resumeAt, resumeAt <= Date() {
            protectionEnabled = true
            self.resumeAt = nil
        }
        return AGHStatus(
            protectionEnabled: protectionEnabled,
            running: true,
            version: "v0.107.52",
            dnsAddresses: ["127.0.0.1:53", "[::1]:53"],
            protectionDisabledDuration: resumeAt.map { Int($0.timeIntervalSinceNow * 1000) }
        )
    }

    func fetchStats() async throws -> AGHStats {
        AGHStats(
            numDnsQueries: 5678,
            numBlockedFiltering: 1234,
            numReplacedSafebrowsing: 12,
            avgProcessingTime: 0.042
        )
    }

    func setProtection(enabled: Bool, duration: TimeInterval?) async throws {
        protectionEnabled = enabled
        resumeAt = enabled ? nil : duration.map { Date().addingTimeInterval($0) }
    }
}
