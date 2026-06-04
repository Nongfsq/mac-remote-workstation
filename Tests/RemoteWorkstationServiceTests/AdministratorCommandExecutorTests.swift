import XCTest
import RemoteWorkstationCore
@testable import RemoteWorkstationService

final class AdministratorCommandExecutorTests: XCTestCase {
    func testAllowsFixedEnableCommandsThroughOsascript() async throws {
        let mock = MockCommandExecutor()
        let executor = AdministratorCommandExecutor(executor: mock)

        for command in PowerCommandPlan.enableACPolicy() {
            _ = try await executor.run(command)
        }

        let invocations = await mock.recordedInvocations()
        XCTAssertEqual(invocations.count, 2)
        XCTAssertEqual(invocations[0].executable, "/usr/bin/osascript")
        XCTAssertTrue(invocations[0].arguments.joined(separator: " ").contains("with administrator privileges"))
        XCTAssertTrue(invocations[1].arguments.joined(separator: " ").contains("disablesleep"))
    }

    func testRejectsArbitraryCommands() async {
        let executor = AdministratorCommandExecutor(executor: MockCommandExecutor())
        let command = CommandInvocation(executable: "/bin/rm", arguments: ["-rf", "/"])

        do {
            _ = try await executor.run(command)
            XCTFail("Expected unsupported command to be rejected")
        } catch let error as AdministratorCommandError {
            XCTAssertEqual(error, .unsupportedCommand(command))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
