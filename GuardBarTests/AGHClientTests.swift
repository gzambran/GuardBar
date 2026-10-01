//
//  AGHClientTests.swift
//  GuardBarTests
//

import Foundation
import Testing
@testable import GuardBar

struct AGHConnectionTests {
    private func url(host: String, port: Int = 80) -> String? {
        AGHConnection(host: host, port: port, username: "admin", password: "pw").baseURL?.absoluteString
    }

    @Test func plainHostUsesHTTPAndPort() {
        #expect(url(host: "192.168.1.2", port: 3000) == "http://192.168.1.2:3000")
    }

    @Test func explicitSchemeIsKept() {
        #expect(url(host: "https://adguard.local", port: 443) == "https://adguard.local:443")
        #expect(url(host: "HTTP://adguard.local/", port: 8080) == "http://adguard.local:8080")
    }

    @Test func ipv6HostIsBracketed() {
        #expect(url(host: "fd00::1") == "http://[fd00::1]:80")
    }

    @Test func emptyHostHasNoURL() {
        #expect(url(host: "  ") == nil)
    }

    @Test func demoRequiresBothCredentials() {
        #expect(AGHConnection(host: "x", port: 80, username: "demo", password: "testing").isDemo)
        #expect(!AGHConnection(host: "x", port: 80, username: "demo", password: "other").isDemo)
    }
}

struct AGHClientTests {
    let transport = StubTransport()

    private func makeClient() -> AGHClient {
        let connection = AGHConnection(host: "192.168.1.2", port: 3000, username: "admin", password: "secret")
        return AGHClient(connection: connection, transport: transport.send)
    }

    @Test func fetchStatusSendsAuthAndDecodes() async throws {
        transport.body = Data("""
        {"protection_enabled": false, "running": true, "version": "v0.107.52",
         "dns_addresses": ["127.0.0.1"], "protection_disabled_duration": 90000}
        """.utf8)

        let status = try await makeClient().fetchStatus()

        #expect(status == makeStatus(enabled: false, disabledDuration: 90000).withAddresses(["127.0.0.1"]))
        let request = try #require(transport.requests.first)
        #expect(request.url?.absoluteString == "http://192.168.1.2:3000/control/status")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Basic YWRtaW46c2VjcmV0")
    }

    @Test func statusDecodesWithoutPauseField() async throws {
        // Older AdGuard Home versions don't report protection_disabled_duration
        transport.body = Data(#"{"protection_enabled": true, "running": true}"#.utf8)

        let status = try await makeClient().fetchStatus()

        #expect(status.protectionEnabled)
        #expect(status.protectionDisabledDuration == nil)
    }

    @Test func fetchStatsDecodes() async throws {
        transport.body = Data("""
        {"num_dns_queries": 200, "num_blocked_filtering": 50,
         "num_replaced_safebrowsing": 0, "avg_processing_time": 0.01}
        """.utf8)

        let stats = try await makeClient().fetchStats()

        #expect(stats == sampleStats)
    }

    @Test func timedPauseSendsDurationInMilliseconds() async throws {
        try await makeClient().setProtection(enabled: false, duration: 300)

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/control/protection")
        let body = try JSONSerialization.jsonObject(with: request.httpBody!) as? [String: Any]
        #expect(body?["enabled"] as? Bool == false)
        #expect(body?["duration"] as? Int == 300_000)
    }

    @Test func enablingSendsNoDuration() async throws {
        try await makeClient().setProtection(enabled: true, duration: nil)

        let body = try JSONSerialization.jsonObject(with: transport.requests[0].httpBody!) as? [String: Any]
        #expect(body?["enabled"] as? Bool == true)
        #expect(body?["duration"] == nil)
    }

    @Test(arguments: [
        (401, AGHError.unauthorized),
        (403, AGHError.unauthorized),
        (429, AGHError.rateLimited),
        (500, AGHError.http(500)),
    ])
    func httpErrorsMap(statusCode: Int, expected: AGHError) async {
        transport.statusCode = statusCode

        await #expect(throws: expected) {
            try await makeClient().fetchStatus()
        }
    }

    @Test(arguments: [
        (URLError.Code.timedOut, AGHError.timedOut),
        (URLError.Code.cannotConnectToHost, AGHError.cannotReach("http://192.168.1.2:3000")),
        (URLError.Code.cannotFindHost, AGHError.cannotReach("http://192.168.1.2:3000")),
    ])
    func networkErrorsMap(code: URLError.Code, expected: AGHError) async {
        transport.error = URLError(code)

        await #expect(throws: expected) {
            try await makeClient().fetchStatus()
        }
    }

    @Test func malformedJSONIsInvalidResponse() async {
        transport.body = Data("not json".utf8)

        await #expect(throws: AGHError.invalidResponse) {
            try await makeClient().fetchStats()
        }
    }
}

struct DemoAGHClientTests {
    @Test func timedPauseReportsRemainingDuration() async throws {
        let demo = DemoAGHClient()

        try await demo.setProtection(enabled: false, duration: 60)
        let status = try await demo.fetchStatus()

        #expect(!status.protectionEnabled)
        let remaining = try #require(status.protectionDisabledDuration)
        #expect((55_000...60_000).contains(remaining))
    }

    @Test func enablingClearsPause() async throws {
        let demo = DemoAGHClient()

        try await demo.setProtection(enabled: false, duration: 60)
        try await demo.setProtection(enabled: true, duration: nil)
        let status = try await demo.fetchStatus()

        #expect(status.protectionEnabled)
        #expect(status.protectionDisabledDuration == nil)
    }
}

private extension AGHStatus {
    func withAddresses(_ addresses: [String]) -> AGHStatus {
        AGHStatus(
            protectionEnabled: protectionEnabled,
            running: running,
            version: version,
            dnsAddresses: addresses,
            protectionDisabledDuration: protectionDisabledDuration
        )
    }
}
