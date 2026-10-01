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
    let protectionOn: Bool
    /// End of a timed pause, if one is running
    let disabledUntil: Date?
    let errorMessage: String?
    
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
                        if status == nil {
                            Text("Loading...")
                                .font(.title3)
                                .fontWeight(.semibold)
                        } else if let disabledUntil {
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                let remaining = disabledUntil.timeIntervalSince(context.date)
                                Text(remaining > 0
                                     ? "Re-enabling in \(Self.formatRemainingTime(remaining))"
                                     : "Re-enabling...")
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

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }
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
        if status == nil {
            return "shield"
        }
        
        if disabledUntil != nil {
            return "clock.badge.exclamationmark.fill"
        }
        return protectionOn ? "shield.fill" : "shield.slash.fill"
    }
    
    private var statusColor: Color {
        // Show neutral gray when loading or no status
        if status == nil {
            return .secondary
        }
        
        if disabledUntil != nil {
            return .orange
        }
        return protectionOn ? .green : .red
    }

    static func formatRemainingTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval.rounded(.up))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        // Preview loading state
        HeaderView(
            status: nil,
            protectionOn: false,
            disabledUntil: nil,
            errorMessage: nil
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
            protectionOn: false,
            disabledUntil: Date().addingTimeInterval(300),
            errorMessage: nil
        )
        
        Divider()
        
        // Preview with protection on and a connection error
        HeaderView(
            status: AGHStatus(
                protectionEnabled: true,
                running: true,
                version: "0.107.0",
                dnsAddresses: ["192.168.1.2"]
            ),
            protectionOn: true,
            disabledUntil: nil,
            errorMessage: "Connection timed out. Check your host and port."
        )
    }
    .frame(width: 340)
}
