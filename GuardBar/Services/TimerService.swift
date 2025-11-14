//
//  TimerService.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import Foundation
import Combine

class TimerService: ObservableObject {
    @Published var isTimerActive = false
    @Published var remainingTime: TimeInterval = 0
    @Published var endTime: Date?
    
    private var timer: Timer?
    private var reenableTask: Task<Void, Never>?
    
    func scheduleReEnable(after duration: TimeInterval, action: @escaping () async -> Void) {
        cancelTimer()

        isTimerActive = true
        remainingTime = duration
        endTime = Date().addingTimeInterval(duration)

        // Update UI every second
        // Note: [weak self] prevents retain cycle - Timer retains closure, closure weakly references self
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let endTime = self.endTime else { return }
            
            self.remainingTime = max(0, endTime.timeIntervalSinceNow)
            
            // Don't cancel here - just stop the UI timer when countdown reaches 0
            if self.remainingTime <= 0 {
                self.timer?.invalidate()
                self.timer = nil
            }
        }
        
        // Schedule the actual re-enable action
        reenableTask = Task {
            // Ensure cleanup happens even if action fails
            defer {
                Task { @MainActor in
                    self.isTimerActive = false
                    self.remainingTime = 0
                    self.endTime = nil
                    self.reenableTask = nil
                }
            }

            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

            // Execute the re-enable action
            await action()
        }
    }
    
    func cancelTimer() {
        timer?.invalidate()
        timer = nil
        reenableTask?.cancel()
        reenableTask = nil
        isTimerActive = false
        remainingTime = 0
        endTime = nil
    }
    
    func formatRemainingTime() -> String {
        let hours = Int(remainingTime) / 3600
        let minutes = (Int(remainingTime) % 3600) / 60
        let seconds = Int(remainingTime) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}
