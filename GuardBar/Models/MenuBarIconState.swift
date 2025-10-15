//
//  MenuBarIconState.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import AppKit

/// Represents the different states of the menu bar icon
enum MenuBarIconState {
    case protectionOn       // Filled shield - Ad blocking is active
    case protectionOff      // Shield with slash - Ad blocking is disabled
    case timerActive        // Clock icon - Temporary disable timer is running
    case error              // Shield with slash - Connection error or offline
    case loading            // Shield outline - Initial loading state
    
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
}
