import Foundation
import RemoteWorkstationCore

public struct StoredWorkstationState: Codable, Sendable, Equatable {
    public var isModeActive: Bool
    public var savedSnapshot: PowerSettingsSnapshot?
    public var eventLog: [WorkstationEvent]
    public var configuration: WorkstationConfiguration

    public init(
        isModeActive: Bool = false,
        savedSnapshot: PowerSettingsSnapshot? = nil,
        eventLog: [WorkstationEvent] = [],
        configuration: WorkstationConfiguration = WorkstationConfiguration()
    ) {
        self.isModeActive = isModeActive
        self.savedSnapshot = savedSnapshot
        self.eventLog = eventLog
        self.configuration = configuration
    }
}

public actor WorkstationStore {
    private let url: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(url: URL = WorkstationStore.defaultURL()) {
        self.url = url
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder = JSONDecoder()
    }

    public func load() -> StoredWorkstationState {
        guard let data = try? Data(contentsOf: url),
              let state = try? decoder.decode(StoredWorkstationState.self, from: data) else {
            return StoredWorkstationState()
        }
        return state
    }

    public func save(_ state: StoredWorkstationState) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(state)
        try data.write(to: url, options: [.atomic])
    }

    public func appendEvent(_ event: WorkstationEvent) throws -> StoredWorkstationState {
        var state = load()
        state.eventLog.insert(event, at: 0)
        state.eventLog = Array(state.eventLog.prefix(50))
        try save(state)
        return state
    }

    public static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base
            .appendingPathComponent("MacRemoteWorkstation", isDirectory: true)
            .appendingPathComponent("state.json")
    }
}
