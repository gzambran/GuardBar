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
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Image(systemName: "gear.badge.questionmark")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    Text("Welcome to GuardBar")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Manage your AdGuard Home from the menu bar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    Text("To get started, you'll need:")
                        .font(.body)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "server.rack")
                                .font(.system(size: 20))
                                .foregroundColor(.accentColor)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AdGuard Home Server Address")
                                    .font(.callout)
                                    .fontWeight(.medium)
                                Text("IP address or hostname")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "person.badge.key")
                                .font(.system(size: 20))
                                .foregroundColor(.accentColor)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Admin Credentials")
                                    .font(.callout)
                                    .fontWeight(.medium)
                                Text("Username and password")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 24)

                Button {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                } label: {
                    Text("Open Settings")
                        .font(.body)
                        .fontWeight(.medium)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 24)

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Quit GuardBar")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 14)
        }
        .frame(width: 420)
    }
}

#Preview {
    SetupView()
}
