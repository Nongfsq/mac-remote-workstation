import Foundation

public enum PrivilegedHelperClientError: Error, LocalizedError {
    case connectionUnavailable
    case helperReturnedFailure(String)

    public var errorDescription: String? {
        switch self {
        case .connectionUnavailable:
            return "Privileged helper connection is unavailable."
        case let .helperReturnedFailure(message):
            return message
        }
    }
}

public final class PrivilegedHelperClient: @unchecked Sendable {
    private let connectionFactory: @Sendable () -> NSXPCConnection

    public init(
        connectionFactory: @escaping @Sendable () -> NSXPCConnection = {
            let connection = NSXPCConnection(
                machServiceName: HelperConstants.machServiceName,
                options: .privileged
            )
            connection.remoteObjectInterface = NSXPCInterface(with: RemoteWorkstationHelperXPC.self)
            connection.resume()
            return connection
        }
    ) {
        self.connectionFactory = connectionFactory
    }

    public func getStatus() async throws -> HelperResponse {
        try await call { proxy, reply in
            proxy.getStatus(reply: reply)
        }
    }

    public func enableWorkstationMode() async throws -> HelperResponse {
        try await call { proxy, reply in
            proxy.enableWorkstationMode(reply: reply)
        }
    }

    public func disableWorkstationMode() async throws -> HelperResponse {
        try await call { proxy, reply in
            proxy.disableWorkstationMode(reply: reply)
        }
    }

    public func restoreSnapshot() async throws -> HelperResponse {
        try await call { proxy, reply in
            proxy.restoreSnapshot(reply: reply)
        }
    }

    public func runVerification() async throws -> HelperResponse {
        try await call { proxy, reply in
            proxy.runVerification(reply: reply)
        }
    }

    public func sleepDisplayForClosedLidIfNeeded() async throws -> HelperResponse {
        try await call { proxy, reply in
            proxy.sleepDisplayForClosedLidIfNeeded(reply: reply)
        }
    }

    private func call(
        _ invoke: @escaping (RemoteWorkstationHelperXPC, @escaping (NSDictionary) -> Void) -> Void
    ) async throws -> HelperResponse {
        let connection = connectionFactory()
        defer { connection.invalidate() }

        return try await withCheckedThrowingContinuation { continuation in
            let proxy = connection.remoteObjectProxyWithErrorHandler { error in
                continuation.resume(throwing: error)
            } as? RemoteWorkstationHelperXPC

            guard let proxy else {
                continuation.resume(throwing: PrivilegedHelperClientError.connectionUnavailable)
                return
            }

            invoke(proxy) { dictionary in
                do {
                    let response = try HelperResponseCodec.response(from: dictionary)
                    if response.ok {
                        continuation.resume(returning: response)
                    } else {
                        continuation.resume(
                            throwing: PrivilegedHelperClientError.helperReturnedFailure(response.message)
                        )
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
