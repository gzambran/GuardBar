//
//  SetupView.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/11/25.
//

import SwiftUI

/// Displays a setup prompt when AdGuard Home connection is not configured
struct SetupView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gear.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Setup Required")
                .font(.headline)
            
            Text("Please configure your AdGuard Home connection in Settings.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            SettingsLink {
                Text("Open Settings")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 300, height: 300)
    }
}

#Preview {
    SetupView()
}
