import XCTest
@testable import RemoteWorkstationCore

final class PolicyAndCommandTests: XCTestCase {
    func testEnablePolicyAllowsACAttachedNotCharging() throws {
        let policy = WorkstationPolicy()
        let battery = BatteryStatus(
            source: .acPower,
            percentage: 82,
            isACAttached: true,
            isCharging: false,
            rawSummary: ""
        )

        XCTAssertNoThrow(try policy.validateEnable(status: battery))
    }

    func testEnablePolicyRejectsBatteryPower() {
        let policy = WorkstationPolicy()
        let battery = BatteryStatus(
            source: .batteryPower,
            percentage: 90,
            isACAttached: false,
            isCharging: false,
            rawSummary: ""
        )

        XCTAssertThrowsError(try policy.validateEnable(status: battery)) { error in
            XCTAssertEqual(error as? WorkstationPolicyError, .requiresACPower)
        }
    }

    func testEnableCommandPlanUsesOnlyFixedPmsetInvocations() {
        let commands = PowerCommandPlan.enableACPolicy()

        XCTAssertEqual(commands, [
            CommandInvocation(
                executable: "/usr/bin/pmset",
                arguments: ["-c", "sleep", "0", "displaysleep", "1", "disksleep", "0", "womp", "1", "tcpkeepalive", "1"]
            ),
            CommandInvocation(executable: "/usr/bin/pmset", arguments: ["disablesleep", "1"])
        ])
    }

    func testWorkstationModePreviewIncludesClosedLidDisplaySleepAction() {
        let commands = PowerCommandPlan.workstationModePreview()

        XCTAssertEqual(commands.dropLast(), PowerCommandPlan.enableACPolicy())
        XCTAssertEqual(commands.last, CommandInvocation(executable: "/usr/bin/pmset", arguments: ["displaysleepnow"]))
    }

    func testRestoreCommandsAlwaysDisableSleepDisabledFirst() {
        let snapshot = PowerSettingsSnapshot(
            acSleep: 1,
            acDisplaySleep: 10,
            acDiskSleep: 10,
            acWakeOnMagicPacket: 1,
            acTCPKeepAlive: 1,
            sleepDisabled: true
        )

        let commands = PowerCommandPlan.restoreCommands(from: snapshot)

        XCTAssertEqual(commands.first, CommandInvocation(executable: "/usr/bin/pmset", arguments: ["disablesleep", "0"]))
        XCTAssertEqual(commands.last?.arguments, ["-c", "sleep", "1", "displaysleep", "10", "disksleep", "10", "womp", "1", "tcpkeepalive", "1"])
    }
}
