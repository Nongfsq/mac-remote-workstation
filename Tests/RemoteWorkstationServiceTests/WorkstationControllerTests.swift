import XCTest
import RemoteWorkstationCore
@testable import RemoteWorkstationService

private struct StaticReader: PowerStatusReading {
    let status: WorkstationStatus

    func readStatus(helper: HelperStatus, isModeActive: Bool, events: [WorkstationEvent]) async throws -> WorkstationStatus {
        var copy = status
        copy.helper = helper
        copy.isModeActive = isModeActive || status.snapshot.sleepDisabled
        copy.eventLog = events
        return copy
    }
}

final class WorkstationControllerTests: XCTestCase {
    func testEnableRunsFixedCommandsAndPersistsSnapshot() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("state.json")
        let store = WorkstationStore(url: tempURL)
        let executor = MockCommandExecutor()
        let status = WorkstationStatus(
            battery: BatteryStatus(source: .acPower, percentage: 82, isACAttached: true, isCharging: false, rawSummary: ""),
            snapshot: PowerSettingsSnapshot(acSleep: 1, acDisplaySleep: 10, acDiskSleep: 10, acWakeOnMagicPacket: 1, acTCPKeepAlive: 1),
            clamshell: ClamshellStatus(causesSleep: true, isClosed: false, sleepDisabled: false),
            helper: .installed,
            isModeActive: false
        )
        let controller = WorkstationController(
            reader: StaticReader(status: status),
            executor: executor,
            store: store,
            configuration: WorkstationConfiguration(shouldSleepDisplayOnEnable: false)
        )

        _ = try await controller.enableWorkstationMode()

        let invocations = await executor.recordedInvocations()
        XCTAssertEqual(invocations, PowerCommandPlan.enableACPolicy())
        let stored = await store.load()
        XCTAssertTrue(stored.isModeActive)
        XCTAssertEqual(stored.savedSnapshot?.acSleep, 1)
    }

    func testEnableDoesNotSleepDisplayByDefault() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("state.json")
        let store = WorkstationStore(url: tempURL)
        let executor = MockCommandExecutor()
        let status = WorkstationStatus(
            battery: BatteryStatus(source: .acPower, percentage: 82, isACAttached: true, isCharging: false, rawSummary: ""),
            snapshot: PowerSettingsSnapshot(acSleep: 1, acDisplaySleep: 10, acDiskSleep: 10, acWakeOnMagicPacket: 1, acTCPKeepAlive: 1),
            clamshell: ClamshellStatus(causesSleep: true, isClosed: false, sleepDisabled: false),
            helper: .installed,
            isModeActive: false
        )
        let controller = WorkstationController(
            reader: StaticReader(status: status),
            executor: executor,
            store: store
        )

        _ = try await controller.enableWorkstationMode()

        let invocations = await executor.recordedInvocations()
        XCTAssertFalse(invocations.contains(PowerCommandPlan.sleepDisplay()))
    }

    func testClosedLidSleepsDisplayWithoutDisablingMode() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("state.json")
        let store = WorkstationStore(url: tempURL)
        let executor = MockCommandExecutor()
        let status = WorkstationStatus(
            battery: BatteryStatus(source: .acPower, percentage: 82, isACAttached: true, isCharging: false, rawSummary: ""),
            snapshot: PowerSettingsSnapshot(acSleep: 0, acDisplaySleep: 1, acDiskSleep: 0, acWakeOnMagicPacket: 1, acTCPKeepAlive: 1, sleepDisabled: true),
            clamshell: ClamshellStatus(causesSleep: true, isClosed: true, sleepDisabled: true),
            helper: .installed,
            isModeActive: true
        )
        var stored = StoredWorkstationState(
            isModeActive: true,
            savedSnapshot: PowerSettingsSnapshot(acSleep: 1, acDisplaySleep: 10, acDiskSleep: 10, acWakeOnMagicPacket: 1, acTCPKeepAlive: 1),
            configuration: WorkstationConfiguration()
        )
        try await store.save(stored)
        let controller = WorkstationController(
            reader: StaticReader(status: status),
            executor: executor,
            store: store
        )

        let didSleepDisplay = try await controller.sleepDisplayForClosedLidIfNeeded()

        XCTAssertTrue(didSleepDisplay)
        let invocations = await executor.recordedInvocations()
        XCTAssertEqual(invocations, [PowerCommandPlan.sleepDisplay()])
        stored = await store.load()
        XCTAssertTrue(stored.isModeActive)
        XCTAssertEqual(stored.eventLog.first?.kind, .info)
    }

    func testClosedLidDisplaySleepDoesNotSpamRecentDuplicateEvents() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("state.json")
        let store = WorkstationStore(url: tempURL)
        let executor = MockCommandExecutor()
        let status = WorkstationStatus(
            battery: BatteryStatus(source: .acPower, percentage: 82, isACAttached: true, isCharging: false, rawSummary: ""),
            snapshot: PowerSettingsSnapshot(acSleep: 0, acDisplaySleep: 1, acDiskSleep: 0, acWakeOnMagicPacket: 1, acTCPKeepAlive: 1, sleepDisabled: true),
            clamshell: ClamshellStatus(causesSleep: true, isClosed: true, sleepDisabled: true),
            helper: .installed,
            isModeActive: true
        )
        let recentEvent = WorkstationEvent(
            date: Date(),
            kind: .info,
            message: WorkstationEventMessage.closedLidDisplaySleepRequested
        )
        try await store.save(
            StoredWorkstationState(
                isModeActive: true,
                savedSnapshot: PowerSettingsSnapshot(acSleep: 1, acDisplaySleep: 10, acDiskSleep: 10, acWakeOnMagicPacket: 1, acTCPKeepAlive: 1),
                eventLog: [recentEvent],
                configuration: WorkstationConfiguration()
            )
        )
        let controller = WorkstationController(
            reader: StaticReader(status: status),
            executor: executor,
            store: store
        )

        let didSleepDisplay = try await controller.sleepDisplayForClosedLidIfNeeded()

        XCTAssertTrue(didSleepDisplay)
        let invocations = await executor.recordedInvocations()
        XCTAssertEqual(invocations, [PowerCommandPlan.sleepDisplay()])
        let stored = await store.load()
        XCTAssertEqual(stored.eventLog, [recentEvent])
    }
}
