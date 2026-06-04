import XCTest
@testable import RemoteWorkstationCore

final class PowerParserTests: XCTestCase {
    func testBatteryParserTreatsACAttachedNotChargingAsACPower() {
        let output = """
        Now drawing from 'AC Power'
         -InternalBattery-0 (id=36241507)\t82%; AC attached; not charging present: true
        """

        let status = PowerParser.parseBatteryStatus(output)

        XCTAssertEqual(status.source, .acPower)
        XCTAssertEqual(status.percentage, 82)
        XCTAssertTrue(status.isACAttached)
        XCTAssertFalse(status.isCharging)
    }

    func testBatteryParserDetectsBatteryPower() {
        let output = """
        Now drawing from 'Battery Power'
         -InternalBattery-0 (id=36241507)\t54%; discharging; 4:22 remaining present: true
        """

        let status = PowerParser.parseBatteryStatus(output)

        XCTAssertEqual(status.source, .batteryPower)
        XCTAssertEqual(status.percentage, 54)
        XCTAssertFalse(status.isACAttached)
        XCTAssertFalse(status.isCharging)
    }

    func testSnapshotParserReadsACBlockAndSleepDisabled() {
        let live = """
        System-wide power settings:
         SleepDisabled\t\t1
        Currently in use:
         sleep                0
        """
        let custom = """
        Battery Power:
         displaysleep         2
         sleep                1
         disksleep            10
        AC Power:
         displaysleep         10
         womp                 1
         sleep                0
         tcpkeepalive         1
         disksleep            0
        """

        let snapshot = PowerParser.parseSnapshot(liveOutput: live, customOutput: custom)

        XCTAssertTrue(snapshot.sleepDisabled)
        XCTAssertEqual(snapshot.acSleep, 0)
        XCTAssertEqual(snapshot.acDisplaySleep, 10)
        XCTAssertEqual(snapshot.acDiskSleep, 0)
        XCTAssertEqual(snapshot.acWakeOnMagicPacket, 1)
        XCTAssertEqual(snapshot.acTCPKeepAlive, 1)
    }

    func testClamshellParserReadsIORegistryBooleans() {
        let output = """
        {
          "AppleClamshellCausesSleep" = Yes
          "AppleClamshellState" = No
          "SleepDisabled" = Yes
        }
        """

        let clamshell = PowerParser.parseClamshellStatus(output)

        XCTAssertEqual(clamshell.causesSleep, true)
        XCTAssertEqual(clamshell.isClosed, false)
        XCTAssertEqual(clamshell.sleepDisabled, true)
    }

    func testDisplaySleepBlockerParserReadsAssertionOwners() {
        let output = """
        Listed by owning process:
           pid 2902(RustDesk): [0x0000488e00059f15] 00:18:04 PreventUserIdleDisplaySleep named: "User requested"
           pid 74874(Codex): [0x000045a200019eb0] 00:30:32 NoIdleSleepAssertion named: "Electron"
        """

        let blockers = PowerParser.parseDisplaySleepBlockers(output)

        XCTAssertEqual(blockers, [
            DisplaySleepBlocker(processID: 2902, processName: "RustDesk", reason: "User requested")
        ])
    }
}
