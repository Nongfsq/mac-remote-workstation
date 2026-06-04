import Foundation
import RemoteWorkstationCore

public protocol PowerStatusReading: Sendable {
    func readStatus(helper: HelperStatus, isModeActive: Bool, events: [WorkstationEvent]) async throws -> WorkstationStatus
}

public struct PowerStatusReader: PowerStatusReading {
    private let executor: CommandExecuting

    public init(executor: CommandExecuting = ProcessCommandExecutor()) {
        self.executor = executor
    }

    public func readStatus(
        helper: HelperStatus = .unknown,
        isModeActive: Bool = false,
        events: [WorkstationEvent] = []
    ) async throws -> WorkstationStatus {
        let batt = try await executor.run(CommandInvocation(executable: "/usr/bin/pmset", arguments: ["-g", "batt"]))
        let live = try await executor.run(CommandInvocation(executable: "/usr/bin/pmset", arguments: ["-g", "live"]))
        let custom = try await executor.run(CommandInvocation(executable: "/usr/bin/pmset", arguments: ["-g", "custom"]))
        let assertions = try await executor.run(CommandInvocation(executable: "/usr/bin/pmset", arguments: ["-g", "assertions"]))
        let clamshell = try await executor.run(
            CommandInvocation(
                executable: "/usr/sbin/ioreg",
                arguments: ["-r", "-k", "AppleClamshellCausesSleep", "-d", "1"]
            )
        )

        let battery = PowerParser.parseBatteryStatus(batt.stdout)
        let snapshot = PowerParser.parseSnapshot(liveOutput: live.stdout, customOutput: custom.stdout)
        let clamshellStatus = PowerParser.parseClamshellStatus(clamshell.stdout)
        let displaySleepBlockers = PowerParser.parseDisplaySleepBlockers(assertions.stdout)

        return WorkstationStatus(
            battery: battery,
            snapshot: snapshot,
            clamshell: clamshellStatus,
            displaySleepBlockers: displaySleepBlockers,
            helper: helper,
            isModeActive: isModeActive || snapshot.sleepDisabled,
            eventLog: events
        )
    }
}
