import Foundation
import RemoteWorkstationCore

public enum AdministratorCommandError: Error, LocalizedError, Equatable {
    case unsupportedCommand(CommandInvocation)

    public var errorDescription: String? {
        switch self {
        case let .unsupportedCommand(command):
            return "Unsupported privileged command: \(command.displayString)"
        }
    }
}

public struct AdministratorCommandExecutor: CommandExecuting {
    private let executor: CommandExecuting

    public init(executor: CommandExecuting = ProcessCommandExecutor()) {
        self.executor = executor
    }

    public func run(_ command: CommandInvocation) async throws -> CommandResult {
        try validate(command)
        let shellCommand = ([command.executable] + command.arguments)
            .map(shellQuote)
            .joined(separator: " ")
        let script = "do shell script \(appleScriptString(shellCommand)) with administrator privileges"
        return try await executor.run(
            CommandInvocation(executable: "/usr/bin/osascript", arguments: ["-e", script])
        )
    }

    private func validate(_ command: CommandInvocation) throws {
        guard command.executable == PowerCommandPlan.pmset else {
            throw AdministratorCommandError.unsupportedCommand(command)
        }

        if command.arguments == ["disablesleep", "0"] ||
            command.arguments == ["disablesleep", "1"] ||
            command.arguments == ["displaysleepnow"] {
            return
        }

        if isAllowedACPolicy(command.arguments) {
            return
        }

        throw AdministratorCommandError.unsupportedCommand(command)
    }

    private func isAllowedACPolicy(_ arguments: [String]) -> Bool {
        guard arguments.first == "-c" else { return false }
        let allowedKeys = Set(["sleep", "displaysleep", "disksleep", "womp", "tcpkeepalive"])
        var index = 1
        var seenKeys = Set<String>()
        while index < arguments.count {
            guard index + 1 < arguments.count else { return false }
            let key = arguments[index]
            let value = arguments[index + 1]
            guard allowedKeys.contains(key), Int(value) != nil else {
                return false
            }
            seenKeys.insert(key)
            index += 2
        }
        return !seenKeys.isEmpty
    }

    private func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private func appleScriptString(_ value: String) -> String {
        "\"" + value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }
}
