//
//  DisablePreset.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import Foundation

enum DisablePreset: String, CaseIterable, Codable, Identifiable {
    case thirtySeconds = "30 seconds"
    case oneMinute = "1 minute"
    case fiveMinutes = "5 minutes"
    case tenMinutes = "10 minutes"
    case fifteenMinutes = "15 minutes"
    case thirtyMinutes = "30 minutes"
    case oneHour = "1 hour"
    case twoHours = "2 hours"
    
    var id: String { rawValue }
    
    var duration: TimeInterval {
        switch self {
        case .thirtySeconds:
            return 30
        case .oneMinute:
            return 60
        case .fiveMinutes:
            return 5 * 60
        case .tenMinutes:
            return 10 * 60
        case .fifteenMinutes:
            return 15 * 60
        case .thirtyMinutes:
            return 30 * 60
        case .oneHour:
            return 60 * 60
        case .twoHours:
            return 2 * 60 * 60
        }
    }
    
    var isEnabledByDefault: Bool {
        switch self {
        case .thirtySeconds, .oneMinute, .fiveMinutes, .thirtyMinutes, .oneHour:
            return true
        case .tenMinutes, .fifteenMinutes, .twoHours:
            return false
        }
    }
}
