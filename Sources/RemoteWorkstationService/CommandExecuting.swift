import Foundation
import RemoteWorkstationCore

public struct CommandResult: Sendable, Equatable {
    public var stdout: String
    public var stderr: String
    public var exitCode: Int32

    public init(stdout: String, stderr: String, exitCode: Int32) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
    }
}

public enum CommandExecutionError: Error, LocalizedError, Equatable {
    case nonZeroExit(command: CommandInvocation, exitCode: Int32, stderr: String)
    case launchFailed(command: CommandInvocation, reason: String)

    public var errorDescription: String? {
        switch self {
        case let .nonZeroExit(command, exitCode, stderr):
            return "\(command.displayString) exited with \(exitCode): \(stderr)"
        case let .launchFailed(command, reason):
            return "\(command.displayString) failed to launch: \(reason)"
        }
    }
}

public protocol CommandExecuting: Sendable {
    func run(_ command: CommandInvocation) async throws -> CommandResult
}

public struct ProcessCommandExecutor: CommandExecuting {
    public init() {}

    public func run(_ command: CommandInvocation) async throws -> CommandResult {
        try await Task.detached(priority: .utility) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: command.executable)
            process.arguments = command.arguments

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            do {
                try process.run()
            } catch {
                throw CommandExecutionError.launchFailed(
                    command: command,
                    reason: error.localizedDescription
                )
            }

            process.waitUntilExit()
            let out = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let err = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let result = CommandResult(stdout: out, stderr: err, exitCode: process.terminationStatus)
            if result.exitCode != 0 {
                throw CommandExecutionError.nonZeroExit(
                    command: command,
                    exitCode: result.exitCode,
                    stderr: result.stderr
                )
            }
            return result
        }.value
    }
}

public actor MockCommandExecutor: CommandExecuting {
    private var outputs: [String: CommandResult]
    public private(set) var invocations: [CommandInvocation] = []

    public init(outputs: [String: CommandResult] = [:]) {
        self.outputs = outputs
    }

    public func set(_ command: CommandInvocation, result: CommandResult) {
        outputs[command.displayString] = result
    }

    public func run(_ command: CommandInvocation) async throws -> CommandResult {
        invocations.append(command)
        let output = outputs[command.displayString]
        return output ?? CommandResult(stdout: "", stderr: "", exitCode: 0)
    }

    public func recordedInvocations() -> [CommandInvocation] {
        invocations
    }
}
