import XCTest
import RemoteWorkstationCore
@testable import RemoteWorkstationService

final class RustDeskCompatibilityManagerTests: XCTestCase {
    func testApplyDisplaySleepCompatibilityWritesOfficialKeepAwakeOptions() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("RustDesk2.toml")
        try FileManager.default.createDirectory(
            at: tempURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try """
        rendezvous_server = 'example'

        [options]
        access-mode = 'full'
        """.write(to: tempURL, atomically: true, encoding: .utf8)
        let manager = RustDeskCompatibilityManager(configURL: tempURL)

        let result = try manager.applyDisplaySleepCompatibility()
        let updated = try String(contentsOf: tempURL, encoding: .utf8)

        XCTAssertTrue(result.changed)
        XCTAssertNotNil(result.backupURL)
        XCTAssertTrue(updated.contains("keep-awake-during-incoming-sessions = 'N'"))
        XCTAssertTrue(updated.contains("keep-awake-during-outgoing-sessions = 'N'"))
        XCTAssertTrue(updated.contains("access-mode = 'full'"))
    }

    func testApplyDisplaySleepCompatibilityIsIdempotent() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("RustDesk2.toml")
        try FileManager.default.createDirectory(
            at: tempURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try """
        [options]
        keep-awake-during-incoming-sessions = 'N'
        keep-awake-during-outgoing-sessions = 'N'
        """.write(to: tempURL, atomically: true, encoding: .utf8)
        let manager = RustDeskCompatibilityManager(configURL: tempURL)

        let result = try manager.applyDisplaySleepCompatibility()

        XCTAssertFalse(result.changed)
        XCTAssertNil(result.backupURL)
    }

    func testStatusDetectsRustDeskBlockerAndCompatibleConfig() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("RustDesk2.toml")
        try FileManager.default.createDirectory(
            at: tempURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try """
        [options]
        keep-awake-during-incoming-sessions = 'N'
        keep-awake-during-outgoing-sessions = 'N'
        """.write(to: tempURL, atomically: true, encoding: .utf8)
        let manager = RustDeskCompatibilityManager(configURL: tempURL)

        let status = manager.status(displaySleepBlockers: [
            DisplaySleepBlocker(processID: 2902, processName: "RustDesk", reason: "User requested")
        ])

        XCTAssertTrue(status.isConfiguredForDisplaySleep)
        XCTAssertTrue(status.hasActiveDisplaySleepBlocker)
    }
}
