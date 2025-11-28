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
    private var pollingService = PollingService()
    private var settingsCancellables = Set<AnyCancellable>()
    private let settingsWindowManager = SettingsWindowManager()

    // Shared settings instance
    let settings = AppSettings()

    deinit {
        // Clean up event monitor to prevent memory leaks
        stopMonitoring()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup application menu with Quit option
        setupApplicationMenu()

        // Create the status item (menu bar icon)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            updateMenuBarIcon(state: .loading)
            button.action = #selector(togglePanel)
            button.target = self
        }

        // Defer panel creation to next run loop iteration to avoid
        // potential AttributeGraph race condition during app launch
        DispatchQueue.main.async { [weak self] in
            self?.setupPanel()
        }

        // Register for NotificationCenter notifications
        // Note: AppDelegate lives for entire app lifetime, so observers are never manually removed
        // They will be automatically cleaned up when the app terminates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleIconStateChange),
            name: .menuBarIconStateChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hidePanel),
            name: .closeMenuBarPopover,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettings),
            name: .openSettings,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChanged),
            name: .settingsChanged,
            object: nil
        )

        // Setup polling
        setupPolling()
        
        // Listen for settings changes
        observeSettingsChanges()
    }
    
    private func setupApplicationMenu() {
        // Create the main menu bar
        let mainMenu = NSMenu()

        // Create the app menu (first menu in menu bar)
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        // Add About menu item
        let aboutItem = NSMenuItem(
            title: "About GuardBar",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        appMenu.addItem(aboutItem)

        appMenu.addItem(NSMenuItem.separator())

        // Add Settings menu item
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        appMenu.addItem(settingsItem)

        appMenu.addItem(NSMenuItem.separator())

        // Add Quit menu item (required by Apple)
        let quitItem = NSMenuItem(
            title: "Quit GuardBar",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenu.addItem(quitItem)

        // Set the main menu
        NSApplication.shared.mainMenu = mainMenu
    }

    @objc func showAbout() {
        // Currently just opens settings window
        // TabView doesn't easily support programmatic selection in this architecture
        openSettings()
    }

    @objc func handleSettingsChanged() {
        // Give SwiftUI time to update the layout before resizing
        Task { @MainActor in
            // Small delay to let SwiftUI recalculate layout
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            resizePanelToFitContent()
        }
    }

    private func resizePanelToFitContent() {
        guard let panel = menuPanel,
              let hostingView = panel.contentView else { return }

        // Force layout update
        hostingView.layout()

        // Get the new fitting size
        let fittingSize = hostingView.fittingSize
        let newWidth = fittingSize.width > 0 ? fittingSize.width : 340
        let newHeight = fittingSize.height > 0 ? fittingSize.height : 545

        // Calculate new origin to keep panel centered under button
        if let button = statusItem?.button,
           let buttonWindow = button.window,
           panel.isVisible {
            // Panel is visible, reposition it
            let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
            let xPosition = buttonFrame.midX - (newWidth / 2)
            let yPosition = buttonFrame.minY - newHeight - 8

            panel.setFrame(
                NSRect(x: xPosition, y: yPosition, width: newWidth, height: newHeight),
                display: true,
                animate: true
            )
        } else {
            // Panel not visible, just resize in place
            panel.setContentSize(NSSize(width: newWidth, height: newHeight))
        }
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

        // Use fixed dimensions - fittingSize crashes on macOS 14.x
        let panelWidth: CGFloat = 460
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

        // Use actual panel size
        let panelFrame = panel.frame
        let panelWidth = panelFrame.width
        let panelHeight = panelFrame.height

        // Center horizontally under the button
        let xPosition = buttonFrame.midX - (panelWidth / 2)

        // Position panel below the menu bar with a small gap
        // buttonFrame.minY is the bottom of the menu bar button
        // Subtract panelHeight to position below, subtract 8 for gap
        let yPosition = buttonFrame.minY - panelHeight - 8

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
