//
//  AGHStatus.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import Foundation

struct AGHStatus: Codable {
    let protectionEnabled: Bool
    let running: Bool
    let version: String?
    let dnsAddresses: [String]?
    
    enum CodingKeys: String, CodingKey {
        case protectionEnabled = "protection_enabled"
        case running
        case version
        case dnsAddresses = "dns_addresses"
    }
}
