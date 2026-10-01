//
//  SettingsWindowManager.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/11/25.
//

import AppKit
import SwiftUI

/// Manages the settings window lifecycle and presentation
class SettingsWindowManager {
    private var windowController: NSWindowController?
    
    /// Show the settings window, creating it if needed
    func showSettings(model: AppModel) {
        if let windowController = windowController {
            // Window exists, just bring it to front on current space
            windowController.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            // Create new settings window
            createSettingsWindow(model: model)
        }
    }
    
    private func createSettingsWindow(model: AppModel) {
        let settingsView = SettingsView(settings: model.settings, model: model)
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 600, height: 400))
        window.center()
        window.isReleasedWhenClosed = false
        
        // This is key: open on current space
        window.collectionBehavior = [.moveToActiveSpace]
        
        let controller = NSWindowController(window: window)
        windowController = controller
        
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
