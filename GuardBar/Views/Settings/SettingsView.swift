//
//  SettingsView.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var password: String = ""
    @State private var showKeychainError = false

    var body: some View {
        TabView {
            ConnectionTab(
                settings: settings,
                password: $password,
                onSettingsChanged: notifySettingsChanged,
                onPasswordChanged: savePasswordToKeychain
            )
            .tabItem {
                Label("Connection", systemImage: "network")
            }
            
            PreferencesTab(
                settings: settings,
                onSettingsChanged: notifySettingsChanged
            )
            .tabItem {
                Label("Preferences", systemImage: "gearshape")
            }
            
            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .padding()
        .onAppear {
            loadPassword()
        }
        .alert("Failed to Save Password", isPresented: $showKeychainError) {
            Button("OK", role: .cancel) {
                // Clear the password field since it wasn't saved
                password = ""
            }
        } message: {
            Text("Unable to securely store your password in the keychain. Please try again.")
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadPassword() {
        if let savedPassword = KeychainService.shared.getPassword() {
            password = savedPassword
        }
    }
    
    private func savePasswordToKeychain(_ newPassword: String) {
        if !newPassword.isEmpty {
            if !KeychainService.shared.savePassword(newPassword) {
                // Show error alert and clear password field
                showKeychainError = true
            }
        }
    }
    
    private func notifySettingsChanged() {
        NotificationCenter.default.post(
            name: .settingsChanged,
            object: nil
        )
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
