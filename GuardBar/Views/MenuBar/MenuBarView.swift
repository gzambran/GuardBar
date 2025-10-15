//
//  MenuBarView.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import SwiftUI
import Combine

struct MenuBarView: View {
    @ObservedObject var settings: AppSettings
    @StateObject private var timerService = TimerService()
    @StateObject private var viewModel = MenuBarViewModel()
    @State private var optimisticProtectionState: Bool? = nil
    
    // Computed property to get the current protection state (optimistic or actual)
    private var currentProtectionState: Bool {
        optimisticProtectionState ?? viewModel.status?.protectionEnabled ?? false
    }
    
    // Check if settings are configured
    private var isConfigured: Bool {
        !settings.host.isEmpty && !settings.username.isEmpty && KeychainService.shared.getPassword() != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !isConfigured {
                // Show setup screen
                SetupView()
            } else {
                // Show main menu
                VStack(spacing: 0) {
                    // Header with status and timer
                    HeaderView(
                        status: viewModel.status,
                        isLoading: viewModel.isLoading,
                        protectionOn: currentProtectionState,
                        timerService: timerService
                    )
                    
                    // Disable options
                    DisableOptionsView(
                        protectionOn: currentProtectionState,
                        isTimerActive: timerService.isTimerActive,
                        hasError: viewModel.errorMessage != nil,
                        enabledPresets: settings.enabledPresets,
                        onDisableForDuration: handleDisableForDuration,
                        onDisablePermanently: handleDisablePermanently,
                        onEnable: handleEnable,
                        onCancelTimer: handleCancelTimer
                    )
                    
                    Divider()
                    
                    // Stats - always reserve space to prevent layout shift
                    Group {
                        if let stats = viewModel.stats {
                            StatsView(stats: stats)
                        } else {
                            // Placeholder to maintain height while stats load
                            Color.clear
                                .frame(height: 97) // Approximate StatsView height
                        }
                    }
                    
                    Divider()
                    
                    Divider()
                    
                    // Actions
                    ActionsView(
                        dashboardHost: settings.host,
                        onRefresh: handleRefresh
                    )
                }
            }
        }
        .onAppear {
            viewModel.configure(settings: settings)
            // Auto-refresh on open to ensure fresh data
            Task {
                await viewModel.refresh()
            }
        }
        // Listen for polling updates
        .onReceive(NotificationCenter.default.publisher(for: .pollingDataUpdated)) { _ in
            Task {
                await viewModel.refresh()
            }
        }
        // Reconfigure when connection settings change
        .onChange(of: settings.host) { viewModel.configure(settings: settings) }
        .onChange(of: settings.port) { viewModel.configure(settings: settings) }
        .onChange(of: settings.username) { viewModel.configure(settings: settings) }
        // Update icon when view state changes (SINGLE SOURCE OF TRUTH)
        .onChange(of: viewModel.status?.protectionEnabled) {
            updateMenuBarIcon()
            // Clear optimistic state when actual status updates
            if let actualStatus = viewModel.status?.protectionEnabled,
               let optimistic = optimisticProtectionState,
               actualStatus == optimistic {
                optimisticProtectionState = nil
            }
        }
        .onChange(of: timerService.isTimerActive) { updateMenuBarIcon() }
        .onChange(of: viewModel.errorMessage) { updateMenuBarIcon() }
        .onChange(of: viewModel.isLoading) { updateMenuBarIcon() }
    }
    
    // MARK: - Action Handlers
    
    private func handleCancelTimer() async {
        // Cancel timer first
        timerService.cancelTimer()
        
        // Make API call to re-enable
        await viewModel.toggleProtection(enable: true, suppressErrors: true)
    }
    
    private func handleDisableForDuration(_ duration: TimeInterval) async {
        // Optimistic update
        optimisticProtectionState = false
        
        // Schedule timer
        timerService.scheduleReEnable(after: duration) {
            // When timer fires, make API call to re-enable
            await viewModel.toggleProtection(enable: true, suppressErrors: true)
        }
        
        // Make API call to disable
        await viewModel.toggleProtection(enable: false, suppressErrors: true)
        
        // Don't close the menu - let user see the timer
        // closePopover()
    }
    
    private func handleDisablePermanently() async {
        // Optimistic update
        optimisticProtectionState = false
        
        // Make API call
        await viewModel.toggleProtection(enable: false, suppressErrors: true)
        
        // Close the menu
        closePopover()
    }
    
    private func handleEnable() async {
        // Optimistic update
        optimisticProtectionState = true
        
        // Make API call
        await viewModel.toggleProtection(enable: true, suppressErrors: true)
        
        // Don't close the menu
        // closePopover()
    }
    
    private func handleRefresh() async {
        await viewModel.refresh()
    }
    
    // MARK: - Helpers
    
    private func closePopover() {
        NotificationCenter.default.post(name: .closeMenuBarPopover, object: nil)
    }
    
    private func updateMenuBarIcon() {
        let state: MenuBarIconState
        
        // Use optimistic state if available, otherwise use actual state
        let protectionOn = optimisticProtectionState ?? (viewModel.status?.protectionEnabled ?? false)
        
        // Don't show loading state in menu bar icon, only show actual protection states
        if viewModel.errorMessage != nil {
            state = .error
        } else if timerService.isTimerActive {
            state = .timerActive
        } else if protectionOn {
            state = .protectionOn
        } else {
            state = .protectionOff
        }
        
        // Post notification to update menu bar icon
        NotificationCenter.default.post(
            name: .menuBarIconStateChanged,
            object: state
        )
    }
}

// MARK: - ViewModel

/// ViewModel to manage API client and state
@MainActor
class MenuBarViewModel: ObservableObject {
    @Published var status: AGHStatus?
    @Published var stats: AGHStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var client: AGHClient?
    
    func configure(settings: AppSettings) {
        guard !settings.host.isEmpty, !settings.username.isEmpty else {
            client = nil
            return
        }
        
        let password = KeychainService.shared.getPassword() ?? ""
        guard !password.isEmpty else {
            client = nil
            return
        }
        
        client = AGHClient(
            host: settings.host,
            port: settings.port,
            username: settings.username,
            password: password
        )
    }
    
    func refresh() async {
        guard let client = client else { return }
        
        isLoading = true
        await client.fetchStatus()
        await client.fetchStats()
        
        // Copy data from client to viewModel
        self.status = client.status
        self.stats = client.stats
        self.errorMessage = client.errorMessage
        self.isLoading = false
    }
    
    func toggleProtection(enable: Bool, suppressErrors: Bool = false) async {
        guard let client = client else { return }
        await client.toggleProtection(enable: enable)
        
        // Update local state
        self.status = client.status
        self.stats = client.stats
        
        // Only show errors if not suppressing them
        if !suppressErrors {
            self.errorMessage = client.errorMessage
        }
    }
}

#Preview {
    MenuBarView(settings: AppSettings())
}
