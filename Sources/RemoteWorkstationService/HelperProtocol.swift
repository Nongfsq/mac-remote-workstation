import Foundation
import RemoteWorkstationCore

@objc public protocol RemoteWorkstationHelperXPC: NSObjectProtocol {
    func getStatus(reply: @escaping (NSDictionary) -> Void)
    func enableWorkstationMode(reply: @escaping (NSDictionary) -> Void)
    func disableWorkstationMode(reply: @escaping (NSDictionary) -> Void)
    func restoreSnapshot(reply: @escaping (NSDictionary) -> Void)
    func runVerification(reply: @escaping (NSDictionary) -> Void)
    func sleepDisplayForClosedLidIfNeeded(reply: @escaping (NSDictionary) -> Void)
}

public enum HelperCommand: String, Codable, Sendable, CaseIterable {
    case getStatus
    case enableWorkstationMode
    case disableWorkstationMode
    case restoreSnapshot
    case runVerification
    case sleepDisplayForClosedLidIfNeeded
}

public struct HelperResponse: Codable, Sendable, Equatable {
    public var ok: Bool
    public var message: String
    public var status: WorkstationStatus?
    public var verification: VerificationReport?

    public init(
        ok: Bool,
        message: String,
        status: WorkstationStatus? = nil,
        verification: VerificationReport? = nil
    ) {
        self.ok = ok
        self.message = message
        self.status = status
        self.verification = verification
    }
}

public enum HelperResponseCodec {
    public static func dictionary(from response: HelperResponse) -> NSDictionary {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(response),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? NSDictionary else {
            return [
                "ok": false,
                "message": "Failed to encode helper response."
            ]
        }
        return dictionary
    }

    public static func response(from dictionary: NSDictionary) throws -> HelperResponse {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(HelperResponse.self, from: data)
    }
}
