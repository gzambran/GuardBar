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
    var menuPanel: NSPanel?
    var eventMonitor: Any?
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
            button.action = #selector(togglePanel)
            button.target = self
        }
        
        // Create the custom panel (dropdown menu)
        setupPanel()
        
        // Listen for icon state change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleIconStateChange),
            name: .menuBarIconStateChanged,
            object: nil
        )
        
        // Listen for close panel notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hidePanel),
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
    
    private func setupPanel() {
        // Create the SwiftUI content with proper background and border
        let menuView = MenuBarView(settings: settings)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
        
        let hostingController = NSHostingController(rootView: menuView)
        
        // Ensure the hosting view is transparent and properly sized
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.masksToBounds = true
        hostingController.view.layer?.cornerRadius = 10
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        
        // Create the panel with fixed size
        let panelWidth: CGFloat = 300
        let panelHeight: CGFloat = 545
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure panel properties for menu bar behavior
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear  // Clear to show SwiftUI background
        panel.hasShadow = false  // Disable panel shadow, use SwiftUI shadow instead
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Set the hosting controller as the content
        panel.contentView = hostingController.view
        
        // Store the panel
        self.menuPanel = panel
    }
    
    @objc func togglePanel() {
        if menuPanel?.isVisible == true {
            hidePanel()
        } else {
            showPanel()
        }
    }
    
    @objc func showPanel() {
        guard let panel = menuPanel,
              let button = statusItem?.button,
              let buttonWindow = button.window else { return }
        
        // Calculate position relative to menu bar button
        let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        
        let panelWidth: CGFloat = 300
        let panelHeight: CGFloat = 545
        
        // Center horizontally under the button, move up slightly to touch menu bar
        let xPosition = buttonFrame.midX - (panelWidth / 2)
        let yPosition = buttonFrame.minY - panelHeight + 5
        
        // Set the panel's position
        panel.setFrameOrigin(NSPoint(x: xPosition, y: yPosition))
        
        // Show the panel
        panel.orderFrontRegardless()
        
        // Start monitoring for clicks outside
        startMonitoring()
    }
    
    @objc func hidePanel() {
        menuPanel?.orderOut(nil)
        stopMonitoring()
    }
    
    private func startMonitoring() {
        // Monitor clicks outside the panel to close it
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self,
                  let panel = self.menuPanel,
                  panel.isVisible else { return }
            
            // Check if click is outside the panel
            let clickLocation = event.locationInWindow
            let panelFrame = panel.frame
            
            // Convert click location to screen coordinates if needed
            if let eventWindow = event.window {
                let screenLocation = eventWindow.convertToScreen(NSRect(origin: clickLocation, size: .zero)).origin
                if !panelFrame.contains(screenLocation) {
                    self.hidePanel()
                }
            } else {
                // Click was in screen coordinates already
                if !panelFrame.contains(clickLocation) {
                    self.hidePanel()
                }
            }
        }
    }
    
    private func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    @objc func openSettings() {
        settingsWindowManager.showSettings(settings: settings)
    }
    
    @objc func handleIconStateChange(_ notification: Notification) {
        if let state = notification.object as? MenuBarIconState {
            updateMenuBarIcon(state: state)
        }
    }
    
    func updateMenuBarIcon(state: MenuBarIconState) {
        guard let button = statusItem?.button else { return }
        
        // Create the icon with the appropriate symbol
        if let image = NSImage(systemSymbolName: state.iconName, accessibilityDescription: "GuardBar") {
            // Make it a template image for native macOS appearance
            image.isTemplate = true
            button.image = image
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
