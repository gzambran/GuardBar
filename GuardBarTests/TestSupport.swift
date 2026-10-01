//
//  TestSupport.swift
//  GuardBarTests
//

import Foundation
@testable import GuardBar

/// Fresh, isolated UserDefaults so tests never touch the real app preferences
func makeDefaults() -> UserDefaults {
    let suiteName = "GuardBarTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}

func makeStatus(enabled: Bool = true, disabledDuration: Int? = nil) -> AGHStatus {
    AGHStatus(
        protectionEnabled: enabled,
        running: true,
        version: "v0.107.52",
        dnsAddresses: nil,
        protectionDisabledDuration: disabledDuration
    )
}

let sampleStats = AGHStats(
    numDnsQueries: 200,
    numBlockedFiltering: 50,
    numReplacedSafebrowsing: 0,
    avgProcessingTime: 0.01
)

/// Scriptable stand-in for AdGuard Home
final class FakeAGHService: AGHService {
    var status = makeStatus()
    var stats = sampleStats
    var fetchError: Error?
    var setProtectionError: Error?
    private(set) var setProtectionCalls: [(enabled: Bool, duration: TimeInterval?)] = []

    func fetchStatus() async throws -> AGHStatus {
        if let fetchError { throw fetchError }
        return status
    }

    func fetchStats() async throws -> AGHStats {
        if let fetchError { throw fetchError }
        return stats
    }

    func setProtection(enabled: Bool, duration: TimeInterval?) async throws {
        setProtectionCalls.append((enabled, duration))
        if let setProtectionError { throw setProtectionError }
        status = makeStatus(enabled: enabled, disabledDuration: duration.map { Int($0 * 1000) })
    }
}

/// Records requests and replies with a canned response
final class StubTransport {
    var statusCode = 200
    var body = Data("{}".utf8)
    var error: Error?
    private(set) var requests: [URLRequest] = []

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        if let error { throw error }
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (body, response)
    }
}
