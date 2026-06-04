import Foundation

public enum PowerParser {
    public static func parseBatteryStatus(_ output: String) -> BatteryStatus {
        let source: PowerSourceKind
        if output.contains("Now drawing from 'AC Power'") {
            source = .acPower
        } else if output.contains("Now drawing from 'Battery Power'") {
            source = .batteryPower
        } else {
            source = .unknown
        }

        let percent = firstMatch(in: output, pattern: #"(\d{1,3})%;"#).flatMap(Int.init)
        let lowered = output.lowercased()
        let acAttached = source == .acPower || lowered.contains("ac attached")
        let charging = lowered.contains("; charging") || lowered.contains("\tcharging")

        return BatteryStatus(
            source: source,
            percentage: percent,
            isACAttached: acAttached,
            isCharging: charging,
            rawSummary: output.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    public static func parseSnapshot(liveOutput: String, customOutput: String) -> PowerSettingsSnapshot {
        var snapshot = PowerSettingsSnapshot()
        snapshot.sleepDisabled = parseSleepDisabled(liveOutput) ?? parseSleepDisabled(customOutput) ?? false

        let acBlock = parseACPowerBlock(customOutput)
        snapshot.acSleep = integerValue(named: "sleep", in: acBlock)
        snapshot.acDisplaySleep = integerValue(named: "displaysleep", in: acBlock)
        snapshot.acDiskSleep = integerValue(named: "disksleep", in: acBlock)
        snapshot.acWakeOnMagicPacket = integerValue(named: "womp", in: acBlock)
        snapshot.acTCPKeepAlive = integerValue(named: "tcpkeepalive", in: acBlock)

        return snapshot
    }

    public static func parseClamshellStatus(_ output: String) -> ClamshellStatus {
        ClamshellStatus(
            causesSleep: boolValue(named: "AppleClamshellCausesSleep", in: output),
            isClosed: boolValue(named: "AppleClamshellState", in: output),
            sleepDisabled: boolValue(named: "SleepDisabled", in: output)
        )
    }

    public static func parseDisplaySleepBlockers(_ output: String) -> [DisplaySleepBlocker] {
        let pattern = #"pid\s+(\d+)\(([^)]+)\):[^\n]*PreventUserIdleDisplaySleep\s+named:\s+"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let range = NSRange(output.startIndex..<output.endIndex, in: output)
        return regex.matches(in: output, range: range).compactMap { match in
            guard match.numberOfRanges == 4,
                  let pidRange = Range(match.range(at: 1), in: output),
                  let nameRange = Range(match.range(at: 2), in: output),
                  let reasonRange = Range(match.range(at: 3), in: output),
                  let pid = Int(output[pidRange]) else {
                return nil
            }
            return DisplaySleepBlocker(
                processID: pid,
                processName: String(output[nameRange]),
                reason: String(output[reasonRange])
            )
        }
    }

    public static func parseSleepDisabled(_ output: String) -> Bool? {
        if let value = firstMatch(in: output, pattern: #"SleepDisabled\s+([01])"#) {
            return value == "1"
        }
        if let value = boolValue(named: "SleepDisabled", in: output) {
            return value
        }
        return nil
    }

    private static func parseACPowerBlock(_ output: String) -> String {
        guard let acRange = output.range(of: "AC Power:") else {
            return output
        }
        let suffix = output[acRange.upperBound...]
        if let nextSection = suffix.range(of: #"\n\S.*Power:"#,
                                          options: .regularExpression) {
            return String(suffix[..<nextSection.lowerBound])
        }
        return String(suffix)
    }

    private static func integerValue(named key: String, in output: String) -> Int? {
        firstMatch(in: output, pattern: #"(?m)^\s*\#(key)\s+(-?\d+)"#).flatMap(Int.init)
    }

    private static func boolValue(named key: String, in output: String) -> Bool? {
        if let yesNo = firstMatch(in: output, pattern: #""\#(key)"\s*=\s*(Yes|No)"#) {
            return yesNo == "Yes"
        }
        if let value = firstMatch(in: output, pattern: #"\#(key)\s*=\s*(Yes|No)"#) {
            return value == "Yes"
        }
        if let numeric = firstMatch(in: output, pattern: #"(?m)^\s*\#(key)\s+([01])"#) {
            return numeric == "1"
        }
        return nil
    }

    private static func firstMatch(in string: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        guard let match = regex.firstMatch(in: string, range: range),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: string) else {
            return nil
        }
        return String(string[captureRange])
    }
}
