//
//  AppModelTests.swift
//  GuardBarTests
//

import Foundation
import Testing
@testable import GuardBar

struct AppModelTests {
    let service = FakeAGHService()
    let settings: AppSettings
    let now = Date(timeIntervalSince1970: 1_000_000)
    var password: String? = "secret"

    init() {
        settings = AppSettings(defaults: makeDefaults())
        settings.host = "192.168.1.2"
        settings.username = "admin"
    }

    private func makeModel() -> AppModel {
        let password = self.password
        let service = self.service
        let now = self.now
        let model = AppModel(
            settings: settings,
            passwordProvider: { password },
            serviceFactory: { _ in service },
            now: { now }
        )
        model.settleDelay = .zero
        model.reconfigure()
        return model
    }

    // MARK: - Configuration

    @Test func configuredWithCompleteCredentials() {
        let model = makeModel()

        #expect(model.isConfigured)
        #expect(model.dashboardURL?.absoluteString == "http://192.168.1.2:80")
    }

    @Test mutating func notConfiguredWithoutPassword() {
        password = nil

        #expect(!makeModel().isConfigured)
    }

    @Test func notConfiguredWithoutUsername() {
        settings.username = ""

        #expect(!makeModel().isConfigured)
    }

    @Test func reconfigureClearsStateWhenConnectionChanges() async {
        let model = makeModel()
        await model.refresh()
        #expect(model.status != nil)

        settings.port = 3000
        model.reconfigure()

        #expect(model.status == nil)
        #expect(model.stats == nil)
        #expect(model.dashboardURL?.absoluteString == "http://192.168.1.2:3000")
    }

    // MARK: - Refresh

    @Test func refreshLoadsStatusAndStats() async {
        let model = makeModel()

        await model.refresh()

        #expect(model.status == service.status)
        #expect(model.stats == sampleStats)
        #expect(model.errorMessage == nil)
        #expect(model.iconState == .protectionOn)
    }

    @Test func refreshFailureShowsErrorAndKeepsLastKnownStatus() async {
        let model = makeModel()
        await model.refresh()

        service.fetchError = AGHError.timedOut
        await model.refresh()

        #expect(model.errorMessage == AGHError.timedOut.localizedDescription)
        #expect(model.status != nil)
        #expect(model.iconState == .error)
    }

    @Test func successfulRefreshClearsError() async {
        let model = makeModel()
        service.fetchError = AGHError.timedOut
        await model.refresh()

        service.fetchError = nil
        await model.refresh()

        #expect(model.errorMessage == nil)
    }

    @Test func pauseStartedElsewhereShowsAsTimer() async {
        service.status = makeStatus(enabled: false, disabledDuration: 120_000)
        let model = makeModel()

        await model.refresh()

        #expect(model.disabledUntil == now.addingTimeInterval(120))
        #expect(model.isTimerActive)
        #expect(model.iconState == .timerActive)
    }

    // MARK: - Toggling

    @Test func timedDisableAsksServerToResume() async {
        let model = makeModel()
        await model.refresh()

        await model.setProtection(enabled: false, duration: 300)

        #expect(service.setProtectionCalls.count == 1)
        #expect(service.setProtectionCalls.first?.enabled == false)
        #expect(service.setProtectionCalls.first?.duration == 300)
        #expect(!model.protectionOn)
        #expect(model.disabledUntil == now.addingTimeInterval(300))
    }

    @Test func permanentDisableHasNoTimer() async {
        let model = makeModel()

        await model.setProtection(enabled: false)

        #expect(service.setProtectionCalls.first?.duration == nil)
        #expect(!model.protectionOn)
        #expect(!model.isTimerActive)
        #expect(model.iconState == .protectionOff)
    }

    @Test func enablingEndsTimer() async {
        let model = makeModel()
        await model.setProtection(enabled: false, duration: 300)

        await model.setProtection(enabled: true)

        #expect(model.protectionOn)
        #expect(!model.isTimerActive)
    }

    @Test func failedToggleRevertsToServerStateAndShowsError() async {
        let model = makeModel()
        await model.refresh()
        service.setProtectionError = AGHError.http(500)

        await model.setProtection(enabled: false)

        // The optimistic OFF must not stick when the server is still ON
        #expect(model.protectionOn)
        #expect(model.errorMessage == AGHError.http(500).localizedDescription)
    }

    @Test mutating func togglingWithoutConnectionDoesNothing() async {
        password = nil
        let model = makeModel()

        await model.setProtection(enabled: false)

        #expect(service.setProtectionCalls.isEmpty)
    }
}
