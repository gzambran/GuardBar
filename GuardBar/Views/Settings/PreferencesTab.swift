//
//  PreferencesTab.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/11/25.
//

import SwiftUI

struct PreferencesTab: View {
    @ObservedObject var settings: AppSettings
    let onSettingsChanged: () -> Void
    
    var body: some View {
        Form {
            Section("General") {
                Toggle("Start at Login", isOn: $settings.startAtLogin)
                
                Toggle("Show Notifications", isOn: $settings.showNotifications)
            }
            
            Section("Polling") {
                Toggle("Enable Auto-Refresh", isOn: $settings.enablePolling)
                    .help("Automatically check AdGuard Home status in the background")
                    .onChange(of: settings.enablePolling) {
                        onSettingsChanged()
                    }
                
                Picker("Poll Interval", selection: $settings.pollingInterval) {
                    Text("15 seconds").tag(15)
                    Text("30 seconds").tag(30)
                    Text("60 seconds").tag(60)
                    Text("2 minutes").tag(120)
                    Text("5 minutes").tag(300)
                }
                .help("How often to check status in the background")
                .disabled(!settings.enablePolling)
                .onChange(of: settings.pollingInterval) {
                    onSettingsChanged()
                }
            }
            
            Section("Timer Presets") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select which timer options appear in the menu:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(DisablePreset.allCases) { preset in
                        Toggle(preset.rawValue, isOn: Binding(
                            get: { settings.enabledPresets.contains(preset) },
                            set: { isEnabled in
                                if isEnabled {
                                    settings.enabledPresets.insert(preset)
                                } else {
                                    settings.enabledPresets.remove(preset)
                                }
                            }
                        ))
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    PreferencesTab(
        settings: AppSettings(),
        onSettingsChanged: {}
    )
}
