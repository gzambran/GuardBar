//
//  AppSettings.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import Foundation
import Combine

class AppSettings: ObservableObject {
    @Published var host: String {
        didSet { UserDefaults.standard.set(host, forKey: "host") }
    }
    
    @Published var port: Int {
        didSet { UserDefaults.standard.set(port, forKey: "port") }
    }
    
    @Published var username: String {
        didSet { UserDefaults.standard.set(username, forKey: "username") }
    }
    
    @Published var startAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(startAtLogin, forKey: "startAtLogin")
            // Actually apply the login item setting
            LoginItemService.shared.setEnabled(startAtLogin)
        }
    }
    
    @Published var showNotifications: Bool {
        didSet { UserDefaults.standard.set(showNotifications, forKey: "showNotifications") }
    }
    
    @Published var enablePolling: Bool {
        didSet { UserDefaults.standard.set(enablePolling, forKey: "enablePolling") }
    }
    
    @Published var pollingInterval: Int {
        didSet { UserDefaults.standard.set(pollingInterval, forKey: "pollingInterval") }
    }
    
    @Published var enabledPresets: Set<DisablePreset> {
        didSet {
            if let encoded = try? JSONEncoder().encode(enabledPresets) {
                UserDefaults.standard.set(encoded, forKey: "enabledPresets")
            }
        }
    }
    
    init() {
        self.host = UserDefaults.standard.string(forKey: "host") ?? "192.168.1.2"
        self.port = UserDefaults.standard.integer(forKey: "port") != 0
            ? UserDefaults.standard.integer(forKey: "port")
            : 80
        self.username = UserDefaults.standard.string(forKey: "username") ?? ""
        
        // Load start at login preference from actual system status
        self.startAtLogin = LoginItemService.shared.isEnabled
        
        self.showNotifications = UserDefaults.standard.bool(forKey: "showNotifications")
        
        // Polling settings - default enabled with 30 second interval
        self.enablePolling = UserDefaults.standard.object(forKey: "enablePolling") as? Bool ?? true
        self.pollingInterval = UserDefaults.standard.integer(forKey: "pollingInterval") != 0
            ? UserDefaults.standard.integer(forKey: "pollingInterval")
            : 30
        
        // Load enabled presets or use defaults
        if let data = UserDefaults.standard.data(forKey: "enabledPresets"),
           let decoded = try? JSONDecoder().decode(Set<DisablePreset>.self, from: data) {
            self.enabledPresets = decoded
        } else {
            // First time - use default enabled presets
            self.enabledPresets = Set(DisablePreset.allCases.filter { $0.isEnabledByDefault })
        }
    }
}
