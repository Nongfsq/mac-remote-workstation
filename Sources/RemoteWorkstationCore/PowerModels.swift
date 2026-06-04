import Foundation

public enum PowerSourceKind: String, Codable, Sendable, Equatable {
    case acPower
    case batteryPower
    case unknown

    public var isAC: Bool { self == .acPower }
}

public struct BatteryStatus: Codable, Sendable, Equatable {
    public var source: PowerSourceKind
    public var percentage: Int?
    public var isACAttached: Bool
    public var isCharging: Bool
    public var rawSummary: String

    public init(
        source: PowerSourceKind,
        percentage: Int?,
        isACAttached: Bool,
        isCharging: Bool,
        rawSummary: String
    ) {
        self.source = source
        self.percentage = percentage
        self.isACAttached = isACAttached
        self.isCharging = isCharging
        self.rawSummary = rawSummary
    }
}

public struct PowerSettingsSnapshot: Codable, Sendable, Equatable {
    public var acSleep: Int?
    public var acDisplaySleep: Int?
    public var acDiskSleep: Int?
    public var acWakeOnMagicPacket: Int?
    public var acTCPKeepAlive: Int?
    public var sleepDisabled: Bool

    public init(
        acSleep: Int? = nil,
        acDisplaySleep: Int? = nil,
        acDiskSleep: Int? = nil,
        acWakeOnMagicPacket: Int? = nil,
        acTCPKeepAlive: Int? = nil,
        sleepDisabled: Bool = false
    ) {
        self.acSleep = acSleep
        self.acDisplaySleep = acDisplaySleep
        self.acDiskSleep = acDiskSleep
        self.acWakeOnMagicPacket = acWakeOnMagicPacket
        self.acTCPKeepAlive = acTCPKeepAlive
        self.sleepDisabled = sleepDisabled
    }
}

public struct ClamshellStatus: Codable, Sendable, Equatable {
    public var causesSleep: Bool?
    public var isClosed: Bool?
    public var sleepDisabled: Bool?

    public init(causesSleep: Bool?, isClosed: Bool?, sleepDisabled: Bool?) {
        self.causesSleep = causesSleep
        self.isClosed = isClosed
        self.sleepDisabled = sleepDisabled
    }
}

public struct DisplaySleepBlocker: Codable, Sendable, Equatable, Identifiable {
    public var processID: Int
    public var processName: String
    public var reason: String

    public var id: String {
        "\(processID)-\(processName)-\(reason)"
    }

    public init(processID: Int, processName: String, reason: String) {
        self.processID = processID
        self.processName = processName
        self.reason = reason
    }
}

public enum HelperStatus: String, Codable, Sendable, Equatable {
    case notInstalled
    case needsApproval
    case installed
    case unavailable
    case unknown
}

public struct WorkstationStatus: Codable, Sendable, Equatable {
    public var battery: BatteryStatus
    public var snapshot: PowerSettingsSnapshot
    public var clamshell: ClamshellStatus
    public var displaySleepBlockers: [DisplaySleepBlocker]
    public var helper: HelperStatus
    public var isModeActive: Bool
    public var lastVerification: VerificationReport?
    public var eventLog: [WorkstationEvent]

    public init(
        battery: BatteryStatus,
        snapshot: PowerSettingsSnapshot,
        clamshell: ClamshellStatus,
        displaySleepBlockers: [DisplaySleepBlocker] = [],
        helper: HelperStatus,
        isModeActive: Bool,
        lastVerification: VerificationReport? = nil,
        eventLog: [WorkstationEvent] = []
    ) {
        self.battery = battery
        self.snapshot = snapshot
        self.clamshell = clamshell
        self.displaySleepBlockers = displaySleepBlockers
        self.helper = helper
        self.isModeActive = isModeActive
        self.lastVerification = lastVerification
        self.eventLog = eventLog
    }
}

public struct VerificationReport: Codable, Sendable, Equatable {
    public enum Result: String, Codable, Sendable {
        case pass
        case warning
        case fail
    }

    public var result: Result
    public var generatedAt: Date
    public var checks: [VerificationCheck]

    public init(result: Result, generatedAt: Date, checks: [VerificationCheck]) {
        self.result = result
        self.generatedAt = generatedAt
        self.checks = checks
    }
}

public struct VerificationCheck: Codable, Sendable, Equatable, Identifiable {
    public enum Severity: String, Codable, Sendable {
        case info
        case warning
        case failure
    }

    public var id: String
    public var title: String
    public var detail: String
    public var severity: Severity

    public init(id: String, title: String, detail: String, severity: Severity) {
        self.id = id
        self.title = title
        self.detail = detail
        self.severity = severity
    }
}

public struct WorkstationEvent: Codable, Sendable, Equatable, Identifiable {
    public enum Kind: String, Codable, Sendable {
        case info
        case enabled
        case disabled
        case warning
        case failure
    }

    public var id: UUID
    public var date: Date
    public var kind: Kind
    public var message: String

    public init(id: UUID = UUID(), date: Date = Date(), kind: Kind, message: String) {
        self.id = id
        self.date = date
        self.kind = kind
        self.message = message
    }
}

public enum WorkstationEventMessage {
    public static let enabledOnAC = "Remote Workstation Mode enabled on AC Power."
    public static let disabledAndRestored = "Remote Workstation Mode disabled and sleep policy restored."
    public static let closedLidDisplaySleepRequested = "Closed lid detected; display sleep requested while workstation mode stays active."
}

public struct WorkstationConfiguration: Codable, Sendable, Equatable {
    public var lowBatteryDisableThreshold: Int
    public var shouldSleepDisplayOnEnable: Bool
    public var shouldSleepDisplayWhenLidCloses: Bool
    public var verificationDurationsMinutes: [Int]

    public init(
        lowBatteryDisableThreshold: Int = 25,
        shouldSleepDisplayOnEnable: Bool = false,
        shouldSleepDisplayWhenLidCloses: Bool = true,
        verificationDurationsMinutes: [Int] = [10, 30]
    ) {
        self.lowBatteryDisableThreshold = lowBatteryDisableThreshold
        self.shouldSleepDisplayOnEnable = shouldSleepDisplayOnEnable
        self.shouldSleepDisplayWhenLidCloses = shouldSleepDisplayWhenLidCloses
        self.verificationDurationsMinutes = verificationDurationsMinutes
    }

    private enum CodingKeys: String, CodingKey {
        case lowBatteryDisableThreshold
        case shouldSleepDisplayOnEnable
        case shouldSleepDisplayWhenLidCloses
        case verificationDurationsMinutes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lowBatteryDisableThreshold = try container.decodeIfPresent(Int.self, forKey: .lowBatteryDisableThreshold) ?? 25
        self.shouldSleepDisplayOnEnable = try container.decodeIfPresent(Bool.self, forKey: .shouldSleepDisplayOnEnable) ?? false
        self.shouldSleepDisplayWhenLidCloses = try container.decodeIfPresent(Bool.self, forKey: .shouldSleepDisplayWhenLidCloses) ?? true
        self.verificationDurationsMinutes = try container.decodeIfPresent([Int].self, forKey: .verificationDurationsMinutes) ?? [10, 30]
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lowBatteryDisableThreshold, forKey: .lowBatteryDisableThreshold)
        try container.encode(shouldSleepDisplayOnEnable, forKey: .shouldSleepDisplayOnEnable)
        try container.encode(shouldSleepDisplayWhenLidCloses, forKey: .shouldSleepDisplayWhenLidCloses)
        try container.encode(verificationDurationsMinutes, forKey: .verificationDurationsMinutes)
    }
}
