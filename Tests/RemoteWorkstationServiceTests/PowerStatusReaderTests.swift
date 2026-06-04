import XCTest
import RemoteWorkstationCore
@testable import RemoteWorkstationService

final class PowerStatusReaderTests: XCTestCase {
    func testReaderBuildsStatusFromCommandOutputs() async throws {
        let executor = MockCommandExecutor(outputs: [
            "/usr/bin/pmset -g batt": CommandResult(
                stdout: "Now drawing from 'AC Power'\n -InternalBattery-0 (id=1)\t82%; AC attached; not charging present: true\n",
                stderr: "",
                exitCode: 0
            ),
            "/usr/bin/pmset -g live": CommandResult(
                stdout: "System-wide power settings:\n SleepDisabled\t\t1\n",
                stderr: "",
                exitCode: 0
            ),
            "/usr/bin/pmset -g custom": CommandResult(
                stdout: "AC Power:\n displaysleep         1\n womp                 1\n sleep                0\n tcpkeepalive         1\n disksleep            0\n",
                stderr: "",
                exitCode: 0
            ),
            "/usr/bin/pmset -g assertions": CommandResult(
                stdout: "pid 2902(RustDesk): [0x1] 00:00:04 PreventUserIdleDisplaySleep named: \"User requested\"\n",
                stderr: "",
                exitCode: 0
            ),
            "/usr/sbin/ioreg -r -k AppleClamshellCausesSleep -d 1": CommandResult(
                stdout: "\"AppleClamshellCausesSleep\" = Yes\n\"AppleClamshellState\" = No\n\"SleepDisabled\" = Yes\n",
                stderr: "",
                exitCode: 0
            )
        ])
        let reader = PowerStatusReader(executor: executor)

        let status = try await reader.readStatus(helper: .installed, isModeActive: false, events: [])

        XCTAssertEqual(status.battery.source, .acPower)
        XCTAssertEqual(status.snapshot.acSleep, 0)
        XCTAssertEqual(status.clamshell.sleepDisabled, true)
        XCTAssertEqual(status.displaySleepBlockers.first?.processName, "RustDesk")
        XCTAssertEqual(status.helper, .installed)
        XCTAssertTrue(status.isModeActive)
    }
}
