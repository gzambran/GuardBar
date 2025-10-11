//
//  HeaderView.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/11/25.
//

import SwiftUI

/// Displays the status header with icon, protection state, and timer information
struct HeaderView: View {
    let status: AGHStatus?
    let isLoading: Bool
    let protectionOn: Bool
    @ObservedObject var timerService: TimerService
    let onCancelTimer: () async -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                // Main status line - icon and text centered together
                HStack(spacing: 12) {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                        .font(.system(size: 32))
                    
                    // Show loading state when no status data yet OR actively loading
                    if status == nil || isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Loading...")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    } else {
                        Text("Ad Blocking: \(protectionOn ? "ON" : "OFF")")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                
                // Timer line below (separate from main status)
                if timerService.isTimerActive {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        
                        Text(timerService.remainingTime > 0 ? "Re-enabling in \(timerService.formatRemainingTime())" : "Re-enabling...")
                            .font(.subheadline)
                            .frame(minWidth: 120, alignment: .leading) // Fixed minimum width
                        
                        Button("Cancel") {
                            Task {
                                await onCancelTimer()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: String {
        // Show neutral icon when loading or no status
        if status == nil || isLoading {
            return "shield"
        }
        
        if timerService.isTimerActive {
            return "clock.badge.exclamationmark.fill"
        }
        return protectionOn ? "shield.fill" : "shield.slash.fill"
    }
    
    private var statusColor: Color {
        // Show neutral gray when loading or no status
        if status == nil || isLoading {
            return .secondary
        }
        
        if timerService.isTimerActive {
            return .orange
        }
        return protectionOn ? .green : .red
    }
}

#Preview {
    VStack(spacing: 0) {
        // Preview loading state
        HeaderView(
            status: nil,
            isLoading: true,
            protectionOn: false,
            timerService: TimerService(),
            onCancelTimer: { }
        )
        
        Divider()
        
        // Preview with timer active
        HeaderView(
            status: AGHStatus(
                protectionEnabled: false,
                running: true,
                version: "0.107.0",
                dnsAddresses: ["192.168.1.2"]
            ),
            isLoading: false,
            protectionOn: false,
            timerService: {
                let service = TimerService()
                service.scheduleReEnable(after: 300) { }
                return service
            }(),
            onCancelTimer: { }
        )
        
        Divider()
        
        // Preview with protection on
        HeaderView(
            status: AGHStatus(
                protectionEnabled: true,
                running: true,
                version: "0.107.0",
                dnsAddresses: ["192.168.1.2"]
            ),
            isLoading: false,
            protectionOn: true,
            timerService: TimerService(),
            onCancelTimer: { }
        )
    }
    .frame(width: 300)
}
