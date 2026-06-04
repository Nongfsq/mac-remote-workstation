import SwiftUI
import RemoteWorkstationCore
import RemoteWorkstationService

@main
struct RemoteWorkstationApp: App {
    @StateObject private var model = DashboardViewModel()

    var body: some Scene {
        WindowGroup("远程工作站") {
            DashboardView()
                .environmentObject(model)
                .frame(minWidth: 680, minHeight: 620)
                .task {
                    await model.refresh()
                    model.startClosedLidDisplayMonitor()
                }
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("刷新状态") {
                    Task { await model.refresh() }
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }
    }
}
