//
//  PollingService.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import Foundation
import Combine

@MainActor
class PollingService: ObservableObject {
    @Published private(set) var lastStatus: AGHStatus?
    @Published private(set) var isPolling = false
    
    private var timer: Timer?
    private var client: AGHClient?
    private var settings: AppSettings?
    
    func configure(settings: AppSettings, client: AGHClient?) {
        self.settings = settings
        self.client = client
    }
    
    func startPolling(interval: TimeInterval) {
        guard interval > 0 else { return }
        
        stopPolling()
        
        isPolling = true
        
        // Create timer on main run loop
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkStatus()
            }
        }
        
        // Fire immediately on start
        Task {
            await checkStatus()
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
        isPolling = false
    }
    
    private func checkStatus() async {
        guard let client = client else { return }
        
        // Fetch status (lightweight, no stats)
        await client.fetchStatus()
        
        // Check if status changed
        if let newStatus = client.status {
            let statusChanged = lastStatus?.protectionEnabled != newStatus.protectionEnabled
            lastStatus = newStatus
            
            if statusChanged {
                // Post notification to update menu bar icon
                updateMenuBarIcon(for: newStatus)
            }
        } else if client.errorMessage != nil {
            // Connection error - update icon to error state
            NotificationCenter.default.post(
                name: .menuBarIconStateChanged,
                object: MenuBarIconState.error
            )
        }
    }
    
    private func updateMenuBarIcon(for status: AGHStatus) {
        let state: MenuBarIconState = status.protectionEnabled ? .protectionOn : .protectionOff
        
        NotificationCenter.default.post(
            name: .menuBarIconStateChanged,
            object: state
        )
    }
}
