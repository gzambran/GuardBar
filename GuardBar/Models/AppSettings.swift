//
//  AppSettings.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import Foundation
import Combine

class AppSettings: ObservableObject {
    private let defaults: UserDefaults

    @Published var host: String {
        didSet { defaults.set(host, forKey: "host") }
    }

    @Published var port: Int {
        didSet { defaults.set(port, forKey: "port") }
    }

    @Published var username: String {
        didSet { defaults.set(username, forKey: "username") }
    }

    @Published var startAtLogin: Bool {
        didSet {
            defaults.set(startAtLogin, forKey: "startAtLogin")
            // Actually apply the login item setting
            LoginItemService.shared.setEnabled(startAtLogin)
        }
    }

    @Published var enablePolling: Bool {
        didSet { defaults.set(enablePolling, forKey: "enablePolling") }
    }

    @Published var pollingInterval: Int {
        didSet { defaults.set(pollingInterval, forKey: "pollingInterval") }
    }

    @Published var enabledPresets: Set<DisablePreset> {
        didSet {
            if let encoded = try? JSONEncoder().encode(enabledPresets) {
                defaults.set(encoded, forKey: "enabledPresets")
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.host = defaults.string(forKey: "host") ?? "192.168.1.2"
        self.port = defaults.integer(forKey: "port") != 0
            ? defaults.integer(forKey: "port")
            : 80
        self.username = defaults.string(forKey: "username") ?? ""

        // Load start at login preference from actual system status
        self.startAtLogin = LoginItemService.shared.isEnabled

        // Polling settings - default enabled with 30 second interval
        self.enablePolling = defaults.object(forKey: "enablePolling") as? Bool ?? true
        self.pollingInterval = defaults.integer(forKey: "pollingInterval") != 0
            ? defaults.integer(forKey: "pollingInterval")
            : 30

        // Load enabled presets or use defaults
        if let data = defaults.data(forKey: "enabledPresets"),
           let decoded = try? JSONDecoder().decode(Set<DisablePreset>.self, from: data) {
            self.enabledPresets = decoded
        } else {
            // First time - use default enabled presets
            self.enabledPresets = Set(DisablePreset.allCases.filter { $0.isEnabledByDefault })
        }
    }

    /// Connection details for the current settings, or nil if anything required is missing
    func connection(password: String?) -> AGHConnection? {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty, !username.isEmpty,
              let password, !password.isEmpty else { return nil }
        return AGHConnection(host: trimmedHost, port: port, username: username, password: password)
    }
}
