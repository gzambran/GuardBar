//
//  ActionsView.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/11/25.
//

import SwiftUI

/// Displays action buttons: Dashboard, Refresh Stats, Settings, Quit
struct ActionsView: View {
    let dashboardHost: String
    let onRefresh: () async -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main actions section
            VStack(alignment: .leading, spacing: 12) {
                MenuButton(title: "Open Dashboard", icon: "safari") {
                    if let url = URL(string: "http://\(dashboardHost)") {
                        NSWorkspace.shared.open(url)
                        // Close the menu after opening dashboard
                        NotificationCenter.default.post(name: .closeMenuBarPopover, object: nil)
                    }
                }
                
                MenuButton(title: "Refresh Stats", icon: "arrow.clockwise") {
                    Task {
                        await onRefresh()
                    }
                }
                
                MenuButton(title: "Settings...", icon: "gearshape") {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }
            }
            .padding()
            
            Divider()
            
            // Quit section
            VStack(alignment: .leading, spacing: 12) {
                MenuButton(title: "Quit GuardBar", icon: "xmark.circle") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding()
        }
    }
}

// Reusable menu button component
struct MenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
    }
}

#Preview {
    ActionsView(
        dashboardHost: "192.168.1.2",
        onRefresh: { }
    )
    .frame(width: 340)
}
