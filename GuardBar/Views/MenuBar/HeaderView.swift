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
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // SLOT 1: Status icon (always 32pt)
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.system(size: 32))
                    .frame(width: 32, height: 32)
                
                // SLOT 2: Text area (FIXED width) - Use overlay to prevent layout changes
                ZStack {
                    // Base layer - always present
                    Text("Ad Blocking: OFF")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .opacity(0) // Invisible but maintains layout
                    
                    // Actual content layers - overlaid on top
                    Group {
                        if status == nil || isLoading {
                            Text("Loading...")
                                .font(.title3)
                                .fontWeight(.semibold)
                        } else if timerService.isTimerActive {
                            if timerService.remainingTime > 0 {
                                Text("Re-enabling in \(timerService.formatRemainingTime())")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            } else {
                                Text("Re-enabling...")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        } else {
                            Text("Ad Blocking: \(protectionOn ? "ON" : "OFF")")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .frame(width: 200, alignment: .leading)
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
            timerService: TimerService()
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
            }()
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
            timerService: TimerService()
        )
    }
    .frame(width: 300)
}
