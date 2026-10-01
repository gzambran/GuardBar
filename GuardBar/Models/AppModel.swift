//
//  AppModel.swift
//  GuardBar
//

import AppKit
import Combine

/// Single source of truth for the AdGuard Home connection, protection state, stats, and polling
@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var status: AGHStatus?
    @Published private(set) var stats: AGHStats?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isConfigured = false
    /// When a timed pause ends. Comes from the server, so pauses started elsewhere show up too.
    @Published private(set) var disabledUntil: Date?
    /// Optimistic state shown while a toggle request is in flight
    @Published private var pendingProtection: Bool?

    let settings: AppSettings
    /// Pause between a toggle and the follow-up refresh, giving AdGuard Home time to apply the change
    var settleDelay: Duration = .milliseconds(500)

    private let passwordProvider: @MainActor () -> String?
    private let serviceFactory: @MainActor (AGHConnection) -> AGHService
    private let now: () -> Date

    private(set) var connection: AGHConnection?
    private var service: AGHService?
    private var isRefreshing = false
    private var pollTimer: Timer?
    private var resumeTimer: Timer?
    private var reconfigureTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(
        settings: AppSettings,
        passwordProvider: @escaping @MainActor () -> String? = { KeychainService.shared.getPassword() },
        serviceFactory: @escaping @MainActor (AGHConnection) -> AGHService = { $0.makeService() },
        now: @escaping () -> Date = Date.init
    ) {
        self.settings = settings
        self.passwordProvider = passwordProvider
        self.serviceFactory = serviceFactory
        self.now = now
    }

    // MARK: - Derived State

    var protectionOn: Bool {
        pendingProtection ?? status?.protectionEnabled ?? false
    }

    var isTimerActive: Bool {
        disabledUntil != nil && !protectionOn
    }

    var iconState: MenuBarIconState {
        MenuBarIconState(
            hasStatus: status != nil,
            hasError: errorMessage != nil,
            isTimerActive: isTimerActive,
            protectionOn: protectionOn
        )
    }

    var dashboardURL: URL? {
        connection?.baseURL
    }

    var isDemo: Bool {
        connection?.isDemo ?? false
    }

    // MARK: - Lifecycle

    /// Connects with the saved settings and begins reacting to settings changes and polling
    func start() {
        reconfigure()
        Task { await refresh() }

        // @Published emits before the property is set, so the debounce also ensures
        // reconfigure() reads the new values
        settings.$host
            .combineLatest(settings.$port, settings.$username)
            .dropFirst()
            .sink { [weak self] _ in self?.credentialsDidChange() }
            .store(in: &cancellables)

        settings.$enablePolling
            .combineLatest(settings.$pollingInterval)
            .sink { [weak self] enabled, interval in
                self?.updatePolling(enabled: enabled, interval: interval)
            }
            .store(in: &cancellables)

        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                Task { await self?.refresh() }
            }
            .store(in: &cancellables)
    }

    /// Call when host, port, username, or password change. Debounced so typing doesn't hit the server per keystroke.
    func credentialsDidChange() {
        reconfigureTask?.cancel()
        reconfigureTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, let self else { return }
            self.reconfigure()
            await self.refresh()
        }
    }

    /// Rebuilds the API client from the current settings and Keychain password
    func reconfigure() {
        let newConnection = settings.connection(password: passwordProvider())
        guard newConnection != connection else { return }

        connection = newConnection
        service = newConnection.map(serviceFactory)
        isConfigured = service != nil
        status = nil
        stats = nil
        errorMessage = nil
        disabledUntil = nil
        resumeTimer?.invalidate()
    }

    // MARK: - Actions

    func refresh() async {
        guard let service else { return }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            async let fetchedStatus = service.fetchStatus()
            async let fetchedStats = service.fetchStats()
            let (newStatus, newStats) = try await (fetchedStatus, fetchedStats)

            // Ignore results from a client that was replaced while the request was in flight
            guard service === self.service else { return }
            apply(newStatus)
            stats = newStats
            errorMessage = nil
        } catch {
            guard service === self.service else { return }
            errorMessage = error.localizedDescription
        }
    }

    /// Turns protection on or off. A `duration` pauses protection and AdGuard Home re-enables it on its own,
    /// even if this app quits or the Mac sleeps.
    func setProtection(enabled: Bool, duration: TimeInterval? = nil) async {
        guard let service else { return }

        pendingProtection = enabled
        defer { pendingProtection = nil }

        do {
            try await service.setProtection(enabled: enabled, duration: duration)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        try? await Task.sleep(for: settleDelay)
        await refresh()
    }

    // MARK: - Private

    private func apply(_ newStatus: AGHStatus) {
        status = newStatus
        disabledUntil = newStatus.disabledUntil(now: now())
        scheduleResumeRefresh()
    }

    /// Refreshes just after a timed pause ends so the UI flips back even with polling off
    private func scheduleResumeRefresh() {
        resumeTimer?.invalidate()
        resumeTimer = nil
        guard let disabledUntil else { return }

        let timer = Timer(fire: disabledUntil.addingTimeInterval(1), interval: 0, repeats: false) { [weak self] _ in
            Task { await self?.refresh() }
        }
        RunLoop.main.add(timer, forMode: .common)
        resumeTimer = timer
    }

    private func updatePolling(enabled: Bool, interval: Int) {
        pollTimer?.invalidate()
        pollTimer = nil
        guard enabled, interval > 0 else { return }

        pollTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: true) { [weak self] _ in
            Task { await self?.poll() }
        }
    }

    private func poll() async {
        // Skip if the previous request is still waiting on a slow server
        guard !isRefreshing else { return }
        await refresh()
    }
}
