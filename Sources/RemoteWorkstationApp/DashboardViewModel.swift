import Foundation
import RemoteWorkstationCore
import RemoteWorkstationService

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var status: WorkstationStatus?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var previewCommands: [CommandInvocation] = PowerCommandPlan.workstationModePreview()
    @Published var helperStatus: HelperStatus = .unknown
    @Published var language: AppLanguage = .chinese
    @Published var rustDeskStatus: RustDeskCompatibilityStatus?
    @Published var rustDeskMessage: String?

    private let controller: WorkstationController
    private let localAdminController: WorkstationController
    private let helperManager: HelperServiceManager
    private let helperClient: PrivilegedHelperClient
    private let rustDeskManager: RustDeskCompatibilityManager
    private var closedLidMonitorTask: Task<Void, Never>?
    private var didRequestDisplaySleepForCurrentClosure = false

    init(
        controller: WorkstationController = WorkstationController(),
        localAdminController: WorkstationController = WorkstationController(
            reader: PowerStatusReader(),
            executor: AdministratorCommandExecutor()
        ),
        helperManager: HelperServiceManager = HelperServiceManager(),
        helperClient: PrivilegedHelperClient = PrivilegedHelperClient(),
        rustDeskManager: RustDeskCompatibilityManager = RustDeskCompatibilityManager()
    ) {
        self.controller = controller
        self.localAdminController = localAdminController
        self.helperManager = helperManager
        self.helperClient = helperClient
        self.rustDeskManager = rustDeskManager
    }

    deinit {
        closedLidMonitorTask?.cancel()
    }

    var canEnable: Bool {
        guard let status else { return false }
        return status.battery.source == .acPower && !status.isModeActive
    }

    var copy: AppCopy {
        AppCopy(language: language)
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            helperStatus = helperManager.status()
            let nextStatus = try await controller.getStatus(helper: helperStatus)
            status = nextStatus
            rustDeskStatus = rustDeskManager.status(displaySleepBlockers: nextStatus.displaySleepBlockers)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func installHelper() async {
        do {
            try helperManager.register()
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fixRustDeskDisplaySleep() async {
        do {
            let result = try rustDeskManager.applyDisplaySleepCompatibility()
            rustDeskMessage = result.changed
                ? copy.rustDeskFixApplied
                : copy.rustDeskAlreadyConfigured
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restartRustDesk() async {
        do {
            try await rustDeskManager.restartRustDesk()
            rustDeskMessage = copy.rustDeskRestarted
            try? await Task.sleep(for: .seconds(2))
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeHelper() async {
        do {
            try helperManager.unregister()
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func enableMode() async {
        isLoading = true
        defer { isLoading = false }
        do {
            if helperStatus == .installed {
                let response = try await helperClient.enableWorkstationMode()
                if let nextStatus = response.status {
                    status = nextStatus
                } else {
                    await refresh()
                }
            } else {
                _ = try await localAdminController.enableWorkstationMode()
                await refresh()
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func disableMode() async {
        isLoading = true
        defer { isLoading = false }
        do {
            if helperStatus == .installed {
                let response = try await helperClient.disableWorkstationMode()
                if let nextStatus = response.status {
                    status = nextStatus
                } else {
                    await refresh()
                }
            } else {
                _ = try await localAdminController.disableWorkstationMode()
                await refresh()
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func verify() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let report: VerificationReport
            if helperStatus == .installed,
               let helperReport = try await helperClient.runVerification().verification {
                report = helperReport
            } else {
                report = try await controller.runVerification()
            }
            if var current = status {
                current.lastVerification = report
                status = current
            } else {
                await refresh()
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startClosedLidDisplayMonitor() {
        guard closedLidMonitorTask == nil else { return }
        closedLidMonitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                await self?.sleepDisplayForNewLidClosure()
            }
        }
    }

    private func sleepDisplayForNewLidClosure() async {
        do {
            let helper = helperManager.status()
            let current = try await controller.getStatus(helper: helper)

            guard current.clamshell.isClosed == true else {
                didRequestDisplaySleepForCurrentClosure = false
                status = current
                return
            }

            guard current.isModeActive, !didRequestDisplaySleepForCurrentClosure else {
                status = current
                return
            }

            if helper == .installed {
                _ = try await helperClient.sleepDisplayForClosedLidIfNeeded()
            } else {
                _ = try await controller.sleepDisplayForClosedLidIfNeeded()
            }
            didRequestDisplaySleepForCurrentClosure = true
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
