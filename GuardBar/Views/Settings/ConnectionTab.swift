//
//  ConnectionTab.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/11/25.
//

import SwiftUI

struct ConnectionTab: View {
    @ObservedObject var settings: AppSettings
    @Binding var password: String
    @State private var isTestingConnection = false
    @State private var connectionTestResult: String?
    @State private var showingConnectionSuccess = false
    @State private var showingConnectionError = false
    
    let onSettingsChanged: () -> Void
    let onPasswordChanged: (String) -> Void
    
    var body: some View {
        Form {
            Section("AdGuard Home Connection") {
                TextField("Host/IP Address", text: $settings.host)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: settings.host) {
                        onSettingsChanged()
                    }
                
                TextField("Port", value: $settings.port, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: settings.port) {
                        onSettingsChanged()
                    }
                
                TextField("Username", text: $settings.username)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: settings.username) {
                        onSettingsChanged()
                    }
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: password) {
                        onPasswordChanged(password)
                    }
                
                HStack {
                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(isTestingConnection || settings.host.isEmpty || settings.username.isEmpty || password.isEmpty)
                    
                    if isTestingConnection {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    
                    Spacer()
                    
                    if let result = connectionTestResult {
                        Text(result)
                            .font(.caption)
                            .foregroundColor(showingConnectionSuccess ? .green : .red)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    // MARK: - Connection Testing
    
    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil
        
        Task {
            let client = AGHClient(
                host: settings.host,
                port: settings.port,
                username: settings.username,
                password: password
            )
            
            let success = await client.testConnection()
            
            await MainActor.run {
                isTestingConnection = false
                showingConnectionSuccess = success
                showingConnectionError = !success
                connectionTestResult = success ? "✓ Connected" : "✗ Failed to connect"
                
                // Clear message after 3 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run {
                        connectionTestResult = nil
                    }
                }
            }
        }
    }
}

#Preview {
    ConnectionTab(
        settings: AppSettings(),
        password: .constant(""),
        onSettingsChanged: {},
        onPasswordChanged: { _ in }
    )
}
