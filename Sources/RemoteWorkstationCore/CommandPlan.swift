import Foundation

public struct CommandInvocation: Codable, Sendable, Equatable {
    public var executable: String
    public var arguments: [String]

    public init(executable: String, arguments: [String]) {
        self.executable = executable
        self.arguments = arguments
    }

    public var displayString: String {
        ([executable] + arguments).joined(separator: " ")
    }
}

public enum PowerCommandPlan {
    public static let pmset = "/usr/bin/pmset"

    public static func enableACPolicy() -> [CommandInvocation] {
        [
            CommandInvocation(
                executable: pmset,
                arguments: ["-c", "sleep", "0", "displaysleep", "1", "disksleep", "0", "womp", "1", "tcpkeepalive", "1"]
            ),
            CommandInvocation(executable: pmset, arguments: ["disablesleep", "1"])
        ]
    }

    public static func workstationModePreview() -> [CommandInvocation] {
        enableACPolicy() + [sleepDisplay()]
    }

    public static func sleepDisplay() -> CommandInvocation {
        CommandInvocation(executable: pmset, arguments: ["displaysleepnow"])
    }

    public static func disableSleepDisabled() -> CommandInvocation {
        CommandInvocation(executable: pmset, arguments: ["disablesleep", "0"])
    }

    public static func restoreCommands(from snapshot: PowerSettingsSnapshot) -> [CommandInvocation] {
        var arguments = ["-c"]
        append("sleep", snapshot.acSleep, to: &arguments)
        append("displaysleep", snapshot.acDisplaySleep, to: &arguments)
        append("disksleep", snapshot.acDiskSleep, to: &arguments)
        append("womp", snapshot.acWakeOnMagicPacket, to: &arguments)
        append("tcpkeepalive", snapshot.acTCPKeepAlive, to: &arguments)

        var commands = [disableSleepDisabled()]
        if arguments.count > 1 {
            commands.append(CommandInvocation(executable: pmset, arguments: arguments))
        }
        return commands
    }

    private static func append(_ key: String, _ value: Int?, to arguments: inout [String]) {
        guard let value else { return }
        arguments.append(contentsOf: [key, String(value)])
    }
}
