//
//  MenuBarIconState.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import AppKit

/// Represents the different states of the menu bar icon
enum MenuBarIconState {
    case protectionOn       // Green shield - Ad blocking is active
    case protectionOff      // Red shield - Ad blocking is disabled
    case timerActive        // Orange clock - Temporary disable timer is running
    case error              // Gray shield slash - Connection error or offline
    case loading            // Gray shield outline - Initial loading state
    
    /// SF Symbol name for the icon
    var iconName: String {
        switch self {
        case .protectionOn:
            return "shield.fill"
        case .protectionOff:
            return "shield.slash.fill"
        case .timerActive:
            return "clock.badge.exclamationmark.fill"
        case .error:
            return "shield.slash.fill"
        case .loading:
            return "shield"
        }
    }
    
    /// Color for the icon
    var iconColor: NSColor {
        switch self {
        case .protectionOn:
            return .systemGreen
        case .protectionOff:
            return .systemRed
        case .timerActive:
            return .systemOrange
        case .error:
            return .systemGray
        case .loading:
            return .systemGray
        }
    }
}
