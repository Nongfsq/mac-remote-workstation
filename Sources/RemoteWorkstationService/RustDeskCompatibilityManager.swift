import Foundation
import RemoteWorkstationCore

public struct RustDeskCompatibilityStatus: Sendable, Equatable {
    public var configURL: URL
    public var isConfiguredForDisplaySleep: Bool
    public var hasActiveDisplaySleepBlocker: Bool

    public init(
        configURL: URL,
        isConfiguredForDisplaySleep: Bool,
        hasActiveDisplaySleepBlocker: Bool
    ) {
        self.configURL = configURL
        self.isConfiguredForDisplaySleep = isConfiguredForDisplaySleep
        self.hasActiveDisplaySleepBlocker = hasActiveDisplaySleepBlocker
    }
}

public struct RustDeskCompatibilityResult: Sendable, Equatable {
    public var configURL: URL
    public var backupURL: URL?
    public var changed: Bool

    public init(configURL: URL, backupURL: URL?, changed: Bool) {
        self.configURL = configURL
        self.backupURL = backupURL
        self.changed = changed
    }
}

public struct RustDeskCompatibilityManager: Sendable {
    public let configURL: URL

    private static let incomingKey = "keep-awake-during-incoming-sessions"
    private static let outgoingKey = "keep-awake-during-outgoing-sessions"

    public init(
        configURL: URL = RustDeskCompatibilityManager.defaultConfigURL()
    ) {
        self.configURL = configURL
    }

    public func status(displaySleepBlockers: [DisplaySleepBlocker]) -> RustDeskCompatibilityStatus {
        let text = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
        return RustDeskCompatibilityStatus(
            configURL: configURL,
            isConfiguredForDisplaySleep: isConfiguredForDisplaySleep(text),
            hasActiveDisplaySleepBlocker: displaySleepBlockers.contains { blocker in
                blocker.processName.localizedCaseInsensitiveContains("RustDesk")
            }
        )
    }

    public func applyDisplaySleepCompatibility() throws -> RustDeskCompatibilityResult {
        let original = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
        let updated = Self.setting(Self.outgoingKey, to: "N", in: Self.setting(Self.incomingKey, to: "N", in: original))

        guard updated != original else {
            return RustDeskCompatibilityResult(configURL: configURL, backupURL: nil, changed: false)
        }

        try FileManager.default.createDirectory(
            at: configURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let backupURL = configURL.appendingPathExtension("backup-\(timestamp())")
        if FileManager.default.fileExists(atPath: configURL.path) {
            try FileManager.default.copyItem(at: configURL, to: backupURL)
        }
        try updated.write(to: configURL, atomically: true, encoding: .utf8)
        return RustDeskCompatibilityResult(configURL: configURL, backupURL: backupURL, changed: true)
    }

    public func restartRustDesk() async throws {
        let executor = ProcessCommandExecutor()
        do {
            _ = try await executor.run(
                CommandInvocation(executable: "/usr/bin/pkill", arguments: ["-TERM", "-x", "RustDesk"])
            )
        } catch CommandExecutionError.nonZeroExit {
            // RustDesk may not be running. Opening the app below is still the desired recovery path.
        }
        try await Task.sleep(for: .seconds(2))
        _ = try await executor.run(
            CommandInvocation(executable: "/usr/bin/open", arguments: ["-a", "RustDesk"])
        )
    }

    private func isConfiguredForDisplaySleep(_ text: String) -> Bool {
        Self.value(for: Self.incomingKey, in: text) == "N" &&
            Self.value(for: Self.outgoingKey, in: text) == "N"
    }

    private static func setting(_ key: String, to value: String, in text: String) -> String {
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        if let existingIndex = lines.firstIndex(where: { line in
            line.trimmingCharacters(in: .whitespaces).hasPrefix("\(key) ")
        }) {
            lines[existingIndex] = "\(key) = '\(value)'"
            return lines.joined(separator: "\n")
        }

        if let optionsIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "[options]" }) {
            lines.insert("\(key) = '\(value)'", at: optionsIndex + 1)
            return lines.joined(separator: "\n")
        }

        let suffix = text.hasSuffix("\n") || text.isEmpty ? "" : "\n"
        return text + suffix + "[options]\n\(key) = '\(value)'"
    }

    private static func value(for key: String, in text: String) -> String? {
        text.split(separator: "\n").compactMap { line -> String? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("\(key)"), let equals = trimmed.firstIndex(of: "=") else {
                return nil
            }
            return trimmed[trimmed.index(after: equals)...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        }.first
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    public static func defaultConfigURL() -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Library/Preferences/com.carriez.RustDesk", isDirectory: true)
            .appendingPathComponent("RustDesk2.toml")
    }
}
