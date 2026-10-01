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
    @State private var clearTask: Task<Void, Never>?

    let onConnectionVerified: () -> Void
    let onPasswordChanged: (String) -> Void

    var body: some View {
        Form {
            Section("AdGuard Home Connection") {
                connectionFields
                testConnectionButton
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - View Components

    private var connectionFields: some View {
        Group {
            TextField("Host/IP Address", text: $settings.host)
                .textFieldStyle(.roundedBorder)
                .onChange(of: settings.host) {
                    connectionTestResult = nil
                }

            TextField("Port", value: $settings.port, format: .number.grouping(.never))
                .textFieldStyle(.roundedBorder)
                .onChange(of: settings.port) {
                    connectionTestResult = nil
                }

            TextField("Username", text: $settings.username)
                .textFieldStyle(.roundedBorder)
                .onChange(of: settings.username) {
                    connectionTestResult = nil
                }

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .onChange(of: password) {
                    onPasswordChanged(password)
                    connectionTestResult = nil
                }
        }
    }

    private var testConnectionButton: some View {
        HStack {
            Button("Test Connection") {
                testConnection()
            }
            .disabled(isTestDisabled)

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

    // MARK: - Computed Properties

    private var isTestDisabled: Bool {
        isTestingConnection ||
        settings.host.isEmpty ||
        settings.username.isEmpty ||
        password.isEmpty
    }

    // MARK: - Connection Testing

    private func testConnection() {
        // Cancel any existing clear task to prevent conflicts
        clearTask?.cancel()
        clearTask = nil

        isTestingConnection = true
        connectionTestResult = nil
        showingConnectionSuccess = false
        showingConnectionError = false

        Task {
            var errorMessage: String?
            if let connection = settings.connection(password: password) {
                do {
                    _ = try await connection.makeService().fetchStatus()
                } catch {
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = "Enter a host, username, and password"
            }
            let success = errorMessage == nil

            await MainActor.run {
                isTestingConnection = false
                showingConnectionSuccess = success
                showingConnectionError = !success

                if success {
                    connectionTestResult = "Connected successfully"
                    // Make sure the menu picks up the verified connection
                    onConnectionVerified()
                } else {
                    connectionTestResult = errorMessage ?? "Failed to connect"
                }

                // Clear any message after 8 seconds
                clearTask = Task {
                    try? await Task.sleep(nanoseconds: 8_000_000_000)
                    await MainActor.run {
                        connectionTestResult = nil
                        showingConnectionSuccess = false
                        showingConnectionError = false
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
        onConnectionVerified: {},
        onPasswordChanged: { _ in }
    )
}
