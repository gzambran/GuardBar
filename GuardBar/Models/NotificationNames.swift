//
//  NotificationNames.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import Foundation

extension Notification.Name {
    /// Posted when the menu bar icon state should change
    static let menuBarIconStateChanged = Notification.Name("MenuBarIconStateChanged")
    
    /// Posted when the menu bar popover should close
    static let closeMenuBarPopover = Notification.Name("CloseMenuBarPopover")
    
    /// Posted when app settings have changed (triggers polling restart, etc.)
    static let settingsChanged = Notification.Name("SettingsChanged")
    
    /// Posted when settings window should open
    static let openSettings = Notification.Name("OpenSettings")
}
