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
        // Note: [weak self] prevents retain cycle - Timer retains closure, closure weakly references self
        // This is safe: Timer → closure (strong), closure → self (weak)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.poll()
            }
        }
        
        // Fire immediately on start
        Task {
            await poll()
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
        isPolling = false
    }
    
    private func poll() async {
        guard let client = client else { return }
        
        // Fetch both status and stats
        await client.fetchStatus()
        await client.fetchStats()
        
        // Notify that new data is available
        NotificationCenter.default.post(name: .pollingDataUpdated, object: nil)
    }
}
