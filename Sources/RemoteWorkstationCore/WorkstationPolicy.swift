import Foundation

public enum WorkstationPolicyError: Error, Equatable, LocalizedError {
    case requiresACPower
    case lowBattery(percent: Int, threshold: Int)

    public var errorDescription: String? {
        switch self {
        case .requiresACPower:
            return "Remote Workstation Mode requires AC Power."
        case let .lowBattery(percent, threshold):
            return "Battery is \(percent)%, below the \(threshold)% safety threshold."
        }
    }
}

public struct WorkstationPolicy: Sendable {
    public var configuration: WorkstationConfiguration

    public init(configuration: WorkstationConfiguration = WorkstationConfiguration()) {
        self.configuration = configuration
    }

    public func validateEnable(status: BatteryStatus) throws {
        guard status.source == .acPower || status.isACAttached else {
            throw WorkstationPolicyError.requiresACPower
        }
        if let percentage = status.percentage,
           percentage < configuration.lowBatteryDisableThreshold {
            throw WorkstationPolicyError.lowBattery(
                percent: percentage,
                threshold: configuration.lowBatteryDisableThreshold
            )
        }
    }

    public func shouldAutoDisable(status: BatteryStatus) -> Bool {
        if status.source != .acPower && !status.isACAttached {
            return true
        }
        if let percentage = status.percentage,
           percentage < configuration.lowBatteryDisableThreshold {
            return true
        }
        return false
    }

    public func verificationReport(status: WorkstationStatus, now: Date = Date()) -> VerificationReport {
        var checks: [VerificationCheck] = []

        checks.append(
            VerificationCheck(
                id: "ac-power",
                title: "AC Power",
                detail: status.battery.source == .acPower
                    ? "Power adapter is connected. Charging is not required for this mode."
                    : "Power adapter is not detected. Mode should stay disabled.",
                severity: status.battery.source == .acPower ? .info : .failure
            )
        )

        checks.append(
            VerificationCheck(
                id: "sleep-disabled",
                title: "System Sleep Disabled",
                detail: status.snapshot.sleepDisabled
                    ? "SleepDisabled is active for closed-lid protection."
                    : "SleepDisabled is off. Closed-lid sleep may still happen.",
                severity: status.snapshot.sleepDisabled ? .info : .warning
            )
        )

        checks.append(
            VerificationCheck(
                id: "ac-idle-sleep",
                title: "AC Idle Sleep",
                detail: status.snapshot.acSleep == 0
                    ? "AC idle system sleep is disabled."
                    : "AC idle system sleep is not disabled.",
                severity: status.snapshot.acSleep == 0 ? .info : .warning
            )
        )

        checks.append(
            VerificationCheck(
                id: "display-sleep-blockers",
                title: "Display Sleep Blockers",
                detail: displaySleepBlockerDetail(status.displaySleepBlockers),
                severity: status.displaySleepBlockers.isEmpty ? .info : .warning
            )
        )

        checks.append(
            VerificationCheck(
                id: "helper",
                title: "Privileged Helper",
                detail: helperDetail(status.helper),
                severity: status.helper == .installed ? .info : .warning
            )
        )

        let result: VerificationReport.Result
        if checks.contains(where: { $0.severity == .failure }) {
            result = .fail
        } else if checks.contains(where: { $0.severity == .warning }) {
            result = .warning
        } else {
            result = .pass
        }

        return VerificationReport(result: result, generatedAt: now, checks: checks)
    }

    private func displaySleepBlockerDetail(_ blockers: [DisplaySleepBlocker]) -> String {
        guard !blockers.isEmpty else {
            return "No app is currently preventing display sleep."
        }
        let names = blockers
            .map { "\($0.processName) (\($0.reason))" }
            .joined(separator: ", ")
        return "These apps are preventing display sleep: \(names)."
    }

    private func helperDetail(_ status: HelperStatus) -> String {
        switch status {
        case .installed:
            return "Helper is installed and can apply fixed privileged power commands."
        case .needsApproval:
            return "Helper registration needs user approval in macOS."
        case .notInstalled:
            return "Helper is not installed yet. Read-only status is available."
        case .unavailable:
            return "Helper is unavailable."
        case .unknown:
            return "Helper status is unknown."
        }
    }
}
