//
//  NotificationNames.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import Foundation

extension Notification.Name {
    static let menuBarIconStateChanged = Notification.Name("menuBarIconStateChanged")
    static let closeMenuBarPopover = Notification.Name("closeMenuBarPopover")
    static let openSettings = Notification.Name("openSettings")
    static let pollingDataUpdated = Notification.Name("pollingDataUpdated")
    static let settingsChanged = Notification.Name("settingsChanged")
}
