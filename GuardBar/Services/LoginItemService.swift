//
//  LoginItemService.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import Foundation
import ServiceManagement

/// Service to manage "Start at Login" functionality
/// Requires macOS 13.0+ for SMAppService API
class LoginItemService {
    static let shared = LoginItemService()
    
    private init() {}
    
    /// Check if the app is currently set to start at login
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    
    /// Enable or disable start at login
    /// - Parameter enabled: Whether to enable start at login
    /// - Returns: True if successful, false otherwise
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                // Register the app to start at login
                try SMAppService.mainApp.register()
                print("✓ Start at login enabled")
                return true
            } else {
                // Unregister the app from starting at login
                try SMAppService.mainApp.unregister()
                print("✓ Start at login disabled")
                return true
            }
        } catch {
            print("✗ Failed to set login item status: \(error.localizedDescription)")
            return false
        }
    }
}
