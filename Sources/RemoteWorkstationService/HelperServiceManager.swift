import Foundation
#if canImport(ServiceManagement)
import ServiceManagement
#endif
import RemoteWorkstationCore

public struct HelperServiceManager: Sendable {
    public static let daemonPlistName = HelperConstants.daemonPlistName

    public init() {}

    public func status() -> HelperStatus {
        #if canImport(ServiceManagement)
        if #available(macOS 13.0, *) {
            let service = SMAppService.daemon(plistName: Self.daemonPlistName)
            switch service.status {
            case .notRegistered:
                return .notInstalled
            case .enabled:
                return .installed
            case .requiresApproval:
                return .needsApproval
            case .notFound:
                return .unavailable
            @unknown default:
                return .unknown
            }
        }
        #endif
        return .unavailable
    }

    public func register() throws {
        #if canImport(ServiceManagement)
        if #available(macOS 13.0, *) {
            try SMAppService.daemon(plistName: Self.daemonPlistName).register()
        }
        #endif
    }

    public func unregister() throws {
        #if canImport(ServiceManagement)
        if #available(macOS 13.0, *) {
            try SMAppService.daemon(plistName: Self.daemonPlistName).unregister()
        }
        #endif
    }
}
