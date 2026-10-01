//
//  AGHStatus.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import Foundation

struct AGHStatus: Codable, Equatable {
    let protectionEnabled: Bool
    let running: Bool
    let version: String?
    let dnsAddresses: [String]?
    /// Milliseconds until AdGuard Home re-enables protection on its own (0 or nil when no pause is scheduled)
    let protectionDisabledDuration: Int?

    init(
        protectionEnabled: Bool,
        running: Bool,
        version: String?,
        dnsAddresses: [String]?,
        protectionDisabledDuration: Int? = nil
    ) {
        self.protectionEnabled = protectionEnabled
        self.running = running
        self.version = version
        self.dnsAddresses = dnsAddresses
        self.protectionDisabledDuration = protectionDisabledDuration
    }

    enum CodingKeys: String, CodingKey {
        case protectionEnabled = "protection_enabled"
        case running
        case version
        case dnsAddresses = "dns_addresses"
        case protectionDisabledDuration = "protection_disabled_duration"
    }

    /// When a timed pause ends, relative to `now`. Nil when protection is on or disabled indefinitely.
    func disabledUntil(now: Date = Date()) -> Date? {
        guard !protectionEnabled,
              let milliseconds = protectionDisabledDuration,
              milliseconds > 0 else { return nil }
        return now.addingTimeInterval(TimeInterval(milliseconds) / 1000)
    }
}
