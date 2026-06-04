import Foundation
import RemoteWorkstationCore

public actor WorkstationController {
    private static let duplicateEventInterval: TimeInterval = 600

    private let reader: PowerStatusReading
    private let executor: CommandExecuting
    private let store: WorkstationStore
    private var policy: WorkstationPolicy

    public init(
        reader: PowerStatusReading? = nil,
        executor: CommandExecuting = ProcessCommandExecutor(),
        store: WorkstationStore = WorkstationStore(),
        configuration: WorkstationConfiguration = WorkstationConfiguration()
    ) {
        self.executor = executor
        self.reader = reader ?? PowerStatusReader(executor: executor)
        self.store = store
        self.policy = WorkstationPolicy(configuration: configuration)
    }

    public func getStatus(helper: HelperStatus = .unknown) async throws -> WorkstationStatus {
        let stored = await store.load()
        var status = try await reader.readStatus(
            helper: helper,
            isModeActive: stored.isModeActive,
            events: stored.eventLog
        )
        status.lastVerification = policy.verificationReport(status: status)
        return status
    }

    public func enableWorkstationMode() async throws -> WorkstationStatus {
        let status = try await getStatus(helper: .installed)
        try policy.validateEnable(status: status.battery)

        var stored = await store.load()
        stored.configuration = policy.configuration
        stored.savedSnapshot = status.snapshot
        stored.isModeActive = true

        for command in PowerCommandPlan.enableACPolicy() {
            _ = try await executor.run(command)
        }
        if policy.configuration.shouldSleepDisplayOnEnable {
            _ = try await executor.run(PowerCommandPlan.sleepDisplay())
        }

        stored.eventLog.insert(
            WorkstationEvent(kind: .enabled, message: WorkstationEventMessage.enabledOnAC),
            at: 0
        )
        try await store.save(stored)
        return try await getStatus(helper: .installed)
    }

    public func disableWorkstationMode() async throws -> WorkstationStatus {
        var stored = await store.load()
        let snapshot = stored.savedSnapshot ?? PowerSettingsSnapshot(
            acSleep: 1,
            acDisplaySleep: 10,
            acDiskSleep: 10,
            acWakeOnMagicPacket: 1,
            acTCPKeepAlive: 1,
            sleepDisabled: false
        )

        for command in PowerCommandPlan.restoreCommands(from: snapshot) {
            _ = try await executor.run(command)
        }

        stored.isModeActive = false
        stored.savedSnapshot = nil
        stored.eventLog.insert(
            WorkstationEvent(kind: .disabled, message: WorkstationEventMessage.disabledAndRestored),
            at: 0
        )
        try await store.save(stored)
        return try await getStatus(helper: .installed)
    }

    public func restoreSnapshot() async throws -> WorkstationStatus {
        try await disableWorkstationMode()
    }

    public func runVerification() async throws -> VerificationReport {
        let status = try await getStatus(helper: .installed)
        return policy.verificationReport(status: status)
    }

    public func sleepDisplayForClosedLidIfNeeded() async throws -> Bool {
        let stored = await store.load()
        guard stored.isModeActive,
              stored.configuration.shouldSleepDisplayWhenLidCloses else {
            return false
        }

        let status = try await getStatus(helper: .installed)
        guard status.battery.source == .acPower || status.battery.isACAttached,
              status.snapshot.sleepDisabled,
              status.clamshell.isClosed == true else {
            return false
        }

        _ = try await executor.run(PowerCommandPlan.sleepDisplay())
        var updated = await store.load()
        let now = Date()
        let hasRecentDuplicate = updated.eventLog.contains { event in
            event.message == WorkstationEventMessage.closedLidDisplaySleepRequested
                && now.timeIntervalSince(event.date) < Self.duplicateEventInterval
        }
        if !hasRecentDuplicate {
            updated.eventLog.insert(
                WorkstationEvent(kind: .info, message: WorkstationEventMessage.closedLidDisplaySleepRequested),
                at: 0
            )
            updated.eventLog = Array(updated.eventLog.prefix(50))
            try await store.save(updated)
        }
        return true
    }

    public func enforceFailsafe() async throws -> Bool {
        let status = try await getStatus(helper: .installed)
        guard policy.shouldAutoDisable(status: status.battery) else {
            return false
        }
        _ = try await disableWorkstationMode()
        return true
    }
}
