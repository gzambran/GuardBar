//
//  GuardBarApp.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import SwiftUI
import Combine

@main
struct GuardBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Don't define any window scenes - menu bar app only
        // Settings window will be created programmatically when needed
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var pollingService = PollingService()
    private var settingsCancellables = Set<AnyCancellable>()
    private let settingsWindowManager = SettingsWindowManager()
    
    // Shared settings instance
    let settings = AppSettings()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item (menu bar icon)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            updateMenuBarIcon(state: .loading)
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create the popover (dropdown menu)
        let menuView = MenuBarView(settings: settings)
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 500)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: menuView)
        
        // Listen for icon state change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleIconStateChange),
            name: .menuBarIconStateChanged,
            object: nil
        )
        
        // Listen for close popover notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closePopover),
            name: .closeMenuBarPopover,
            object: nil
        )
        
        // Listen for open settings notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettings),
            name: .openSettings,
            object: nil
        )
        
        // Setup polling
        setupPolling()
        
        // Listen for settings changes
        observeSettingsChanges()
    }
    
    @objc func openSettings() {
        settingsWindowManager.showSettings(settings: settings)
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if let popover = popover {
                if popover.isShown {
                    popover.performClose(nil)
                } else {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
            }
        }
    }
    
    @objc func handleIconStateChange(_ notification: Notification) {
        if let state = notification.object as? MenuBarIconState {
            updateMenuBarIcon(state: state)
        }
    }
    
    @objc func closePopover() {
        popover?.performClose(nil)
    }
    
    func updateMenuBarIcon(state: MenuBarIconState) {
        guard let button = statusItem?.button else { return }
        
        // Create the icon with the appropriate symbol
        if let image = NSImage(systemSymbolName: state.iconName, accessibilityDescription: "GuardBar") {
            // Tint the image with the appropriate color
            let tintedImage = image.withSymbolConfiguration(
                NSImage.SymbolConfiguration(paletteColors: [state.iconColor])
            )
            button.image = tintedImage
        }
    }
    
    private func setupPolling() {
        Task { @MainActor in
            // Create API client if credentials are configured
            guard !settings.host.isEmpty, !settings.username.isEmpty,
                  let password = KeychainService.shared.getPassword(), !password.isEmpty else {
                return
            }
            
            let client = AGHClient(
                host: settings.host,
                port: settings.port,
                username: settings.username,
                password: password
            )
            
            pollingService.configure(settings: settings, client: client)
            
            // Start polling if enabled
            if settings.enablePolling {
                pollingService.startPolling(interval: TimeInterval(settings.pollingInterval))
            }
        }
    }
    
    private func observeSettingsChanges() {
        // Restart polling when settings change
        settings.$enablePolling
            .sink { [weak self] enabled in
                guard let self = self else { return }
                Task { @MainActor in
                    if enabled {
                        self.pollingService.startPolling(interval: TimeInterval(self.settings.pollingInterval))
                    } else {
                        self.pollingService.stopPolling()
                    }
                }
            }
            .store(in: &settingsCancellables)
        
        settings.$pollingInterval
            .sink { [weak self] interval in
                guard let self = self else { return }
                Task { @MainActor in
                    if self.settings.enablePolling {
                        self.pollingService.startPolling(interval: TimeInterval(interval))
                    }
                }
            }
            .store(in: &settingsCancellables)
        
        // Reconfigure polling when connection settings change
        settings.$host
            .combineLatest(settings.$port, settings.$username)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupPolling()
            }
            .store(in: &settingsCancellables)
    }
}
