//
//  DisableOptionsView.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/11/25.
//

import SwiftUI

/// Displays disable options with timer presets and enable/disable buttons
struct DisableOptionsView: View {
    let protectionOn: Bool
    let isTimerActive: Bool
    let hasError: Bool
    let enabledPresets: Set<DisablePreset>
    let onDisableForDuration: (TimeInterval) async -> Void
    let onDisablePermanently: () async -> Void
    let onEnable: () async -> Void
    
    private var isDisabled: Bool {
        !protectionOn || isTimerActive || hasError
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Disable options section
            VStack(alignment: .leading, spacing: 6) {
                Text("Disable for:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Show only enabled presets from settings, sorted by duration
                ForEach(Array(enabledPresets).sorted(by: { $0.duration < $1.duration }), id: \.self) { preset in
                    Button {
                        guard !isDisabled else { return }
                        Task {
                            await onDisableForDuration(preset.duration)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "clock")
                                .frame(width: 20)
                            Text(preset.rawValue)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(isDisabled ? .secondary : .primary)
                    .opacity(isDisabled ? 0.5 : 1.0)
                    .allowsHitTesting(!isDisabled)
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                // Permanent disable button
                Button {
                    guard !isDisabled else { return }
                    Task {
                        await onDisablePermanently()
                    }
                } label: {
                    HStack {
                        Image(systemName: "minus.circle")
                            .frame(width: 20)
                        Text("Permanently")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(isDisabled ? .secondary : .primary)
                .opacity(isDisabled ? 0.5 : 1.0)
                .allowsHitTesting(!isDisabled)
            }
            
            // Enable button (only show when protection is OFF and no timer is active)
            if !protectionOn && !isTimerActive {
                Button {
                    Task {
                        await onEnable()
                    }
                } label: {
                    HStack {
                        Image(systemName: "shield.fill")
                            .frame(width: 20)
                        Text("Enable Ad Blocking")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
            }
        }
        .padding()
    }
}

#Preview {
    VStack(spacing: 0) {
        // Preview with protection ON (options disabled)
        DisableOptionsView(
            protectionOn: true,
            isTimerActive: false,
            hasError: false,
            enabledPresets: [.thirtySeconds, .oneMinute, .fiveMinutes, .thirtyMinutes, .oneHour],
            onDisableForDuration: { _ in },
            onDisablePermanently: { },
            onEnable: { }
        )
        
        Divider()
        
        // Preview with protection OFF (show enable button)
        DisableOptionsView(
            protectionOn: false,
            isTimerActive: false,
            hasError: false,
            enabledPresets: [.thirtySeconds, .oneMinute, .fiveMinutes, .thirtyMinutes, .oneHour],
            onDisableForDuration: { _ in },
            onDisablePermanently: { },
            onEnable: { }
        )
        
        Divider()
        
        // Preview with timer active (options disabled)
        DisableOptionsView(
            protectionOn: false,
            isTimerActive: true,
            hasError: false,
            enabledPresets: [.thirtySeconds, .oneMinute, .fiveMinutes, .thirtyMinutes, .oneHour],
            onDisableForDuration: { _ in },
            onDisablePermanently: { },
            onEnable: { }
        )
    }
    .frame(width: 300)
}
