//
//  MenuBarView.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(spacing: 0) {
            if !model.isConfigured {
                // Show setup screen
                SetupView()
            } else {
                // Show main menu
                VStack(spacing: 0) {
                    // Header with status and timer
                    HeaderView(
                        status: model.status,
                        protectionOn: model.protectionOn,
                        disabledUntil: model.isTimerActive ? model.disabledUntil : nil,
                        errorMessage: model.errorMessage
                    )

                    // Disable options
                    DisableOptionsView(
                        protectionOn: model.protectionOn,
                        isTimerActive: model.isTimerActive,
                        hasError: model.errorMessage != nil,
                        enabledPresets: settings.enabledPresets,
                        onDisable: { duration in
                            await model.setProtection(enabled: false, duration: duration)
                        },
                        onEnable: {
                            await model.setProtection(enabled: true)
                        }
                    )

                    Divider()

                    // Stats - always reserve space to prevent layout shift
                    Group {
                        if let stats = model.stats {
                            StatsView(stats: stats)
                        } else {
                            // Placeholder to maintain height while stats load
                            Color.clear
                                .frame(height: 97) // Approximate StatsView height
                        }
                    }

                    Divider()

                    // Actions
                    ActionsView(
                        dashboardURL: model.dashboardURL,
                        isDemoMode: model.isDemo,
                        onRefresh: { await model.refresh() }
                    )
                }
                .frame(width: 300)
            }
        }
    }
}

#Preview {
    let settings = AppSettings()
    MenuBarView(model: AppModel(settings: settings), settings: settings)
}
