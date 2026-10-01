//
//  ModelTests.swift
//  GuardBarTests
//

import Foundation
import Testing
@testable import GuardBar

struct AGHStatusTests {
    let now = Date(timeIntervalSince1970: 1_000_000)

    @Test func timedPauseHasEndDate() {
        let status = makeStatus(enabled: false, disabledDuration: 1500)

        #expect(status.disabledUntil(now: now) == now.addingTimeInterval(1.5))
    }

    @Test func noEndDateWhenEnabledOrIndefinite() {
        #expect(makeStatus(enabled: true, disabledDuration: 1500).disabledUntil(now: now) == nil)
        #expect(makeStatus(enabled: false, disabledDuration: 0).disabledUntil(now: now) == nil)
        #expect(makeStatus(enabled: false, disabledDuration: nil).disabledUntil(now: now) == nil)
    }
}

struct AGHStatsTests {
    @Test func blockPercentage() {
        #expect(sampleStats.blockPercentage == 25)
    }

    @Test func blockPercentageWithNoQueries() {
        let stats = AGHStats(numDnsQueries: 0, numBlockedFiltering: 0, numReplacedSafebrowsing: 0, avgProcessingTime: 0)

        #expect(stats.blockPercentage == 0)
    }
}

struct MenuBarIconStateTests {
    @Test(arguments: [
        (true, true, true, true, MenuBarIconState.error),
        (false, false, false, false, .loading),
        (true, false, true, false, .timerActive),
        (true, false, false, true, .protectionOn),
        (true, false, false, false, .protectionOff),
    ])
    func derivesState(hasStatus: Bool, hasError: Bool, isTimerActive: Bool, protectionOn: Bool, expected: MenuBarIconState) {
        let state = MenuBarIconState(
            hasStatus: hasStatus,
            hasError: hasError,
            isTimerActive: isTimerActive,
            protectionOn: protectionOn
        )

        #expect(state == expected)
    }
}

struct RemainingTimeFormatTests {
    @Test(arguments: [
        (5.0, "5s"),
        (4.2, "5s"),
        (60.0, "1m 0s"),
        (125.0, "2m 5s"),
        (3600.0, "1h 0m"),
        (7260.0, "2h 1m"),
    ])
    func formats(interval: TimeInterval, expected: String) {
        #expect(HeaderView.formatRemainingTime(interval) == expected)
    }
}

struct DisablePresetTests {
    @Test func durationsAreAscendingInDeclarationOrder() {
        let durations = DisablePreset.allCases.map(\.duration)

        #expect(durations == durations.sorted())
        #expect(DisablePreset.twoHours.duration == 7200)
    }
}

struct AppSettingsTests {
    @Test func defaultsOnFirstLaunch() {
        let settings = AppSettings(defaults: makeDefaults())

        #expect(settings.port == 80)
        #expect(settings.enablePolling)
        #expect(settings.pollingInterval == 30)
        #expect(settings.enabledPresets == Set(DisablePreset.allCases.filter(\.isEnabledByDefault)))
    }

    @Test func valuesPersistAcrossInstances() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        settings.host = "adguard.local"
        settings.port = 3000
        settings.username = "admin"
        settings.enablePolling = false
        settings.pollingInterval = 120
        settings.enabledPresets = [.twoHours]

        let reloaded = AppSettings(defaults: defaults)

        #expect(reloaded.host == "adguard.local")
        #expect(reloaded.port == 3000)
        #expect(reloaded.username == "admin")
        #expect(!reloaded.enablePolling)
        #expect(reloaded.pollingInterval == 120)
        #expect(reloaded.enabledPresets == [.twoHours])
    }

    @Test func connectionTrimsHostAndRequiresCredentials() {
        let settings = AppSettings(defaults: makeDefaults())
        settings.host = "  adguard.local "
        settings.username = "admin"

        #expect(settings.connection(password: nil) == nil)
        #expect(settings.connection(password: "")  == nil)
        #expect(settings.connection(password: "pw")?.host == "adguard.local")
    }
}
