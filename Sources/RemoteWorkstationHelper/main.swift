import Foundation
import RemoteWorkstationCore
import RemoteWorkstationService

@main
struct RemoteWorkstationHelperMain {
    static func main() async {
        let controller = WorkstationController()
        let arguments = CommandLine.arguments.dropFirst()

        guard let firstArgument = arguments.first else {
            runXPCService(controller: controller)
            return
        }

        do {
            let response: HelperResponse
            switch firstArgument {
            case "status":
                let status = try await controller.getStatus(helper: .installed)
                response = HelperResponse(ok: true, message: "Status read.", status: status)
            case "enable":
                let status = try await controller.enableWorkstationMode()
                response = HelperResponse(ok: true, message: "Remote Workstation Mode enabled.", status: status)
            case "disable":
                let status = try await controller.disableWorkstationMode()
                response = HelperResponse(ok: true, message: "Remote Workstation Mode disabled.", status: status)
            case "verify":
                let report = try await controller.runVerification()
                response = HelperResponse(ok: true, message: "Verification complete.", verification: report)
            case "sleep-display-if-closed":
                let didSleepDisplay = try await controller.sleepDisplayForClosedLidIfNeeded()
                response = HelperResponse(
                    ok: true,
                    message: didSleepDisplay ? "Closed lid detected; display sleep requested." : "Display sleep not needed."
                )
            case "failsafe":
                let didDisable = try await controller.enforceFailsafe()
                response = HelperResponse(ok: true, message: didDisable ? "Failsafe disabled mode." : "Failsafe not needed.")
            default:
                response = HelperResponse(
                    ok: false,
                    message: "Usage: RemoteWorkstationHelper status|enable|disable|verify|sleep-display-if-closed|failsafe"
                )
            }

            try printJSON(response)
        } catch {
            let response = HelperResponse(ok: false, message: error.localizedDescription)
            try? printJSON(response)
            Foundation.exit(1)
        }
    }

    private static func runXPCService(controller: WorkstationController) {
        let service = RemoteWorkstationXPCService(controller: controller)
        let delegate = HelperListenerDelegate(service: service)
        let monitor = FailsafeMonitor(controller: controller)
        let listener = NSXPCListener(machServiceName: HelperConstants.machServiceName)
        listener.delegate = delegate
        listener.resume()
        monitor.start()
        RunLoop.main.run()
    }

    private static func printJSON<T: Encodable>(_ value: T) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }
}

private final class HelperListenerDelegate: NSObject, NSXPCListenerDelegate {
    private let service: RemoteWorkstationXPCService

    init(service: RemoteWorkstationXPCService) {
        self.service = service
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: RemoteWorkstationHelperXPC.self)
        newConnection.exportedObject = service
        newConnection.resume()
        return true
    }
}

private final class RemoteWorkstationXPCService: NSObject, RemoteWorkstationHelperXPC, @unchecked Sendable {
    private final class ReplyBox: @unchecked Sendable {
        let reply: (NSDictionary) -> Void

        init(_ reply: @escaping (NSDictionary) -> Void) {
            self.reply = reply
        }
    }

    private let controller: WorkstationController

    init(controller: WorkstationController) {
        self.controller = controller
    }

    func getStatus(reply: @escaping (NSDictionary) -> Void) {
        let controller = controller
        respond(reply) {
            let status = try await controller.getStatus(helper: .installed)
            return HelperResponse(ok: true, message: "Status read.", status: status)
        }
    }

    func enableWorkstationMode(reply: @escaping (NSDictionary) -> Void) {
        let controller = controller
        respond(reply) {
            let status = try await controller.enableWorkstationMode()
            return HelperResponse(ok: true, message: "Remote Workstation Mode enabled.", status: status)
        }
    }

    func disableWorkstationMode(reply: @escaping (NSDictionary) -> Void) {
        let controller = controller
        respond(reply) {
            let status = try await controller.disableWorkstationMode()
            return HelperResponse(ok: true, message: "Remote Workstation Mode disabled.", status: status)
        }
    }

    func restoreSnapshot(reply: @escaping (NSDictionary) -> Void) {
        let controller = controller
        respond(reply) {
            let status = try await controller.restoreSnapshot()
            return HelperResponse(ok: true, message: "Snapshot restored.", status: status)
        }
    }

    func runVerification(reply: @escaping (NSDictionary) -> Void) {
        let controller = controller
        respond(reply) {
            let verification = try await controller.runVerification()
            return HelperResponse(ok: true, message: "Verification complete.", verification: verification)
        }
    }

    func sleepDisplayForClosedLidIfNeeded(reply: @escaping (NSDictionary) -> Void) {
        let controller = controller
        respond(reply) {
            let didSleepDisplay = try await controller.sleepDisplayForClosedLidIfNeeded()
            return HelperResponse(
                ok: true,
                message: didSleepDisplay ? "Closed lid detected; display sleep requested." : "Display sleep not needed."
            )
        }
    }

    private func respond(
        _ reply: @escaping (NSDictionary) -> Void,
        operation: @escaping @Sendable () async throws -> HelperResponse
    ) {
        let box = ReplyBox(reply)
        Task {
            do {
                box.reply(HelperResponseCodec.dictionary(from: try await operation()))
            } catch {
                box.reply(HelperResponseCodec.dictionary(from: HelperResponse(ok: false, message: error.localizedDescription)))
            }
        }
    }
}

private final class FailsafeMonitor {
    private let controller: WorkstationController
    private let displaySleeper: ClosedLidDisplaySleeper
    private var timer: Timer?

    init(controller: WorkstationController) {
        self.controller = controller
        self.displaySleeper = ClosedLidDisplaySleeper(controller: controller)
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [controller, displaySleeper] _ in
            Task {
                _ = try? await controller.enforceFailsafe()
                await displaySleeper.sleepDisplayForNewLidClosure()
            }
        }
    }
}

private actor ClosedLidDisplaySleeper {
    private let controller: WorkstationController
    private var didRequestDisplaySleepForCurrentClosure = false

    init(controller: WorkstationController) {
        self.controller = controller
    }

    func sleepDisplayForNewLidClosure() async {
        guard let status = try? await controller.getStatus(helper: .installed) else {
            return
        }

        if status.clamshell.isClosed == true {
            guard status.isModeActive, !didRequestDisplaySleepForCurrentClosure else {
                return
            }
            _ = try? await controller.sleepDisplayForClosedLidIfNeeded()
            didRequestDisplaySleepForCurrentClosure = true
        } else {
            didRequestDisplaySleepForCurrentClosure = false
        }
    }
}
