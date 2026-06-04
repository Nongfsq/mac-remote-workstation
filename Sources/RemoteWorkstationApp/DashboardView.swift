import SwiftUI
import RemoteWorkstationCore
import RemoteWorkstationService

struct DashboardView: View {
    @EnvironmentObject private var model: DashboardViewModel

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HeaderView(availableWidth: proxy.size.width)
                    if let error = model.errorMessage {
                        BannerView(title: model.copy.actionNeeded, detail: error, tint: .red)
                    }
                    if let status = model.status {
                        StatusGrid(status: status, availableWidth: proxy.size.width)
                        ControlPanel(status: status, availableWidth: proxy.size.width)
                        RustDeskCompatibilityPanel()
                        VerificationPanel(report: status.lastVerification)
                        EventLogView(events: status.eventLog)
                    } else {
                        ProgressView(model.copy.readingPower)
                            .frame(maxWidth: .infinity, minHeight: 260)
                    }
                }
                .padding(.top, 34)
                .padding(.horizontal, horizontalPadding(for: proxy.size.width))
                .padding(.bottom, 32)
                .frame(maxWidth: 1240, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        if width < 700 { return 18 }
        if width < 980 { return 24 }
        return 32
    }
}

private struct HeaderView: View {
    @EnvironmentObject private var model: DashboardViewModel
    let availableWidth: CGFloat

    var body: some View {
        if availableWidth < 720 {
            VStack(alignment: .leading, spacing: 14) {
                titleBlock
                toolbar
            }
        } else {
            HStack(alignment: .top, spacing: 20) {
                titleBlock
                Spacer(minLength: 16)
                toolbar
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(model.copy.appName)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(model.copy.subtitle)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var toolbar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                languagePicker
                refreshButton
            }
            VStack(alignment: .trailing, spacing: 8) {
                languagePicker
                refreshButton
            }
        }
        .frame(maxWidth: availableWidth < 720 ? .infinity : nil, alignment: .trailing)
    }

    private var languagePicker: some View {
        Picker("", selection: $model.language) {
            ForEach(AppLanguage.allCases) { language in
                Text(language.label).tag(language)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 150)
    }

    private var refreshButton: some View {
        Button {
            Task { await model.refresh() }
        } label: {
            Label(model.copy.refresh, systemImage: "arrow.clockwise")
        }
        .buttonStyle(.bordered)
        .disabled(model.isLoading)
    }
}

private struct StatusGrid: View {
    @EnvironmentObject private var model: DashboardViewModel
    let status: WorkstationStatus
    let availableWidth: CGFloat

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            MetricCard(
                title: model.copy.power,
                value: status.battery.source == .acPower ? model.copy.acPower : model.copy.battery,
                detail: status.battery.isCharging ? model.copy.charging : model.copy.notChargingOK,
                symbol: "powerplug",
                tint: status.battery.source == .acPower ? .green : .orange
            )
            MetricCard(
                title: model.copy.mode,
                value: status.isModeActive ? model.copy.active : model.copy.off,
                detail: status.snapshot.sleepDisabled ? model.copy.sleepDisabledOn : model.copy.sleepDisabledOff,
                symbol: status.isModeActive ? "lock.open.laptopcomputer" : "lock.laptopcomputer",
                tint: status.isModeActive ? .blue : .gray
            )
            MetricCard(
                title: model.copy.closedLid,
                value: closedLidValue(status.clamshell),
                detail: status.clamshell.sleepDisabled == true ? model.copy.protected : model.copy.maySleep,
                symbol: "rectangle.compress.vertical",
                tint: status.clamshell.sleepDisabled == true ? .green : .orange
            )
            MetricCard(
                title: model.copy.helper,
                value: helperValue(status.helper),
                detail: helperDetail(status.helper),
                symbol: "key.horizontal",
                tint: status.helper == .installed ? .green : .blue
            )
        }
    }

    private var columns: [GridItem] {
        let count: Int
        if availableWidth < 620 {
            count = 1
        } else if availableWidth < 1060 {
            count = 2
        } else {
            count = 4
        }
        return Array(repeating: GridItem(.flexible(minimum: 180), spacing: 14), count: count)
    }

    private func closedLidValue(_ clamshell: ClamshellStatus) -> String {
        if clamshell.isClosed == true { return model.copy.closed }
        if clamshell.isClosed == false { return model.copy.open }
        return model.copy.unknown
    }

    private func helperValue(_ helper: HelperStatus) -> String {
        switch helper {
        case .installed: return model.copy.installed
        case .needsApproval: return model.copy.approve
        case .notInstalled: return model.copy.missing
        case .unavailable: return model.copy.unavailable
        case .unknown: return model.copy.unknown
        }
    }

    private func helperDetail(_ helper: HelperStatus) -> String {
        switch helper {
        case .installed: return model.copy.helperInstalledDetail
        case .needsApproval: return model.copy.helperApprovalDetail
        case .notInstalled: return model.copy.helperMissingDetail
        case .unavailable: return model.copy.helperUnavailableDetail
        case .unknown: return model.copy.helperUnknownDetail
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30, alignment: .leading)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(value)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .background(.quaternary.opacity(0.42), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ControlPanel: View {
    @EnvironmentObject private var model: DashboardViewModel
    let status: WorkstationStatus
    let availableWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if availableWidth < 820 {
                VStack(alignment: .leading, spacing: 14) {
                    copyBlock
                    actionButton
                }
            } else {
                HStack(alignment: .top, spacing: 18) {
                    copyBlock
                    Spacer(minLength: 16)
                    actionButton
                }
            }

            if !model.canEnable && !status.isModeActive {
                BannerView(
                    title: model.copy.acRequired,
                    detail: model.copy.acRequiredDetail,
                    tint: .orange
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(model.copy.plannedCommands)
                    .font(.headline)
                ForEach(model.previewCommands, id: \.displayString) { command in
                    ScrollView(.horizontal, showsIndicators: true) {
                        Text(command.displayString)
                            .font(.system(.callout, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(18)
        .background(.quaternary.opacity(0.32), in: RoundedRectangle(cornerRadius: 8))
    }

    private var copyBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(model.copy.workstationMode)
                .font(.title2.weight(.semibold))
            Text(model.copy.workstationCopy)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 660, alignment: .leading)
    }

    private var actionButton: some View {
        Group {
            if status.isModeActive {
                Button(role: .destructive) {
                    Task { await model.disableMode() }
                } label: {
                    Label(model.copy.disable, systemImage: "stop.circle")
                }
            } else {
                Button {
                    Task { await model.enableMode() }
                } label: {
                    Label(model.copy.enableOnAC, systemImage: "power")
                }
                .disabled(!model.canEnable)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

private struct RustDeskCompatibilityPanel: View {
    @EnvironmentObject private var model: DashboardViewModel

    var body: some View {
        if let rustDeskStatus = model.rustDeskStatus {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.copy.rustDeskCompatibility)
                            .font(.title2.weight(.semibold))
                        Text(detail(for: rustDeskStatus))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 12)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) {
                            actionButtons(for: rustDeskStatus)
                        }
                        VStack(alignment: .trailing, spacing: 8) {
                            actionButtons(for: rustDeskStatus)
                        }
                    }
                }

                if let message = model.rustDeskMessage {
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(rustDeskStatus.configURL.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
            .padding(18)
            .background(.quaternary.opacity(0.32), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func detail(for status: RustDeskCompatibilityStatus) -> String {
        if status.isConfiguredForDisplaySleep && !status.hasActiveDisplaySleepBlocker {
            return model.copy.rustDeskCompatible
        }
        if status.isConfiguredForDisplaySleep && status.hasActiveDisplaySleepBlocker {
            return model.copy.rustDeskNeedsRestart
        }
        return model.copy.rustDeskBlocksDisplaySleep
    }

    @ViewBuilder
    private func actionButtons(for status: RustDeskCompatibilityStatus) -> some View {
        Button {
            Task { await model.fixRustDeskDisplaySleep() }
        } label: {
            Label(model.copy.fixRustDesk, systemImage: "wrench.and.screwdriver")
        }
        .buttonStyle(.bordered)
        .disabled(status.isConfiguredForDisplaySleep)

        Button {
            Task { await model.restartRustDesk() }
        } label: {
            Label(model.copy.restartRustDesk, systemImage: "arrow.clockwise.circle")
        }
        .buttonStyle(.bordered)
        .disabled(!status.isConfiguredForDisplaySleep || !status.hasActiveDisplaySleepBlocker)
    }
}

private struct VerificationPanel: View {
    @EnvironmentObject private var model: DashboardViewModel
    let report: VerificationReport?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(model.copy.verification)
                    .font(.title2.weight(.semibold))
                Spacer(minLength: 12)
                Button {
                    Task { await model.verify() }
                } label: {
                    Label(model.copy.runChecks, systemImage: "checkmark.seal")
                }
                .buttonStyle(.bordered)
            }

            if let report {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(report.checks) { check in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: symbol(for: check.severity))
                                .foregroundStyle(color(for: check.severity))
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(model.copy.verificationTitle(check.title))
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(model.copy.verificationDetail(check.detail))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Text(model.copy.noVerification)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.quaternary.opacity(0.32), in: RoundedRectangle(cornerRadius: 8))
    }

    private func symbol(for severity: VerificationCheck.Severity) -> String {
        switch severity {
        case .info: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .failure: return "xmark.octagon.fill"
        }
    }

    private func color(for severity: VerificationCheck.Severity) -> Color {
        switch severity {
        case .info: return .green
        case .warning: return .orange
        case .failure: return .red
        }
    }
}

private struct EventLogView: View {
    @EnvironmentObject private var model: DashboardViewModel
    let events: [WorkstationEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.copy.recentEvents)
                .font(.title2.weight(.semibold))
            if events.isEmpty {
                Text(model.copy.noEvents)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(visibleEvents) { event in
                    HStack(alignment: .top, spacing: 12) {
                        Text(event.date, style: .time)
                            .foregroundStyle(.secondary)
                            .frame(width: 72, alignment: .leading)
                        Text(model.copy.eventMessage(event.message))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .font(.callout)
                    Divider()
                }
            }
        }
        .padding(18)
        .background(.quaternary.opacity(0.32), in: RoundedRectangle(cornerRadius: 8))
    }

    private var visibleEvents: [WorkstationEvent] {
        var latestDateByMessage: [String: Date] = [:]
        return events.filter { event in
            if let latestDate = latestDateByMessage[event.message],
               abs(latestDate.timeIntervalSince(event.date)) < 600 {
                return false
            }
            latestDateByMessage[event.message] = event.date
            return true
        }
    }
}

private struct BannerView: View {
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}
