import Foundation
import RemoteWorkstationCore

enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese
    case english

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        }
    }
}

struct AppCopy {
    let language: AppLanguage

    static let zh = AppCopy(language: .chinese)

    var appName: String { language == .chinese ? "远程工作站" : "Remote Workstation" }
    var subtitle: String {
        language == .chinese
            ? "插电时让这台 Mac 合盖后继续可远程连接。"
            : "Keep this Mac reachable while plugged in and closed."
    }

    var refresh: String { language == .chinese ? "刷新" : "Refresh" }
    var actionNeeded: String { language == .chinese ? "需要处理" : "Action Needed" }
    var readingPower: String { language == .chinese ? "正在读取电源状态..." : "Reading power state..." }

    var power: String { language == .chinese ? "电源" : "Power" }
    var mode: String { language == .chinese ? "模式" : "Mode" }
    var closedLid: String { language == .chinese ? "合盖" : "Closed Lid" }
    var helper: String { language == .chinese ? "Helper" : "Helper" }
    var acPower: String { language == .chinese ? "已接电" : "AC Power" }
    var battery: String { language == .chinese ? "电池" : "Battery" }
    var charging: String { language == .chinese ? "正在充电" : "Charging" }
    var notChargingOK: String { language == .chinese ? "限充停充也可用" : "Not charging is OK" }
    var active: String { language == .chinese ? "已开启" : "Active" }
    var off: String { language == .chinese ? "已关闭" : "Off" }
    var sleepDisabledOn: String { language == .chinese ? "系统睡眠已禁止" : "SleepDisabled on" }
    var sleepDisabledOff: String { language == .chinese ? "系统睡眠未禁止" : "SleepDisabled off" }
    var open: String { language == .chinese ? "打开" : "Open" }
    var closed: String { language == .chinese ? "已合上" : "Closed" }
    var unknown: String { language == .chinese ? "未知" : "Unknown" }
    var protected: String { language == .chinese ? "策略已保护" : "Protected by policy" }
    var maySleep: String { language == .chinese ? "合盖后可能睡眠" : "May sleep when closed" }
    var installed: String { language == .chinese ? "已安装" : "Installed" }
    var approve: String { language == .chinese ? "待批准" : "Approve" }
    var missing: String { language == .chinese ? "未安装" : "Missing" }
    var unavailable: String { language == .chinese ? "不可用" : "Unavailable" }
    var helperInstalledDetail: String { language == .chinese ? "可执行受保护命令" : "Can apply protected commands" }
    var helperApprovalDetail: String { language == .chinese ? "需要在系统设置批准" : "Approve in System Settings" }
    var helperMissingDetail: String { language == .chinese ? "当前只读，需打包安装" : "Read-only until installed" }
    var helperUnavailableDetail: String {
        language == .chinese
            ? "将使用管理员授权"
            : "Uses admin authorization"
    }
    var helperUnknownDetail: String { language == .chinese ? "尚未验证" : "Status not verified" }

    var workstationMode: String { language == .chinese ? "工作站模式" : "Workstation Mode" }
    var workstationCopy: String {
        language == .chinese
            ? "合盖后请求熄灭屏幕，但系统继续运行；关闭时恢复快照。"
            : "Sleep the display after lid close while the system keeps running; restore on disable."
    }
    var enableOnAC: String { language == .chinese ? "接电开启" : "Enable on AC" }
    var disable: String { language == .chinese ? "关闭模式" : "Disable" }
    var acRequired: String { language == .chinese ? "需要接入电源" : "AC Power Required" }
    var acRequiredDetail: String {
        language == .chinese
            ? "先接上电源。电池限充导致“不在充电”也没有问题。"
            : "Connect power first. AC attached but not charging is safe."
    }
    var plannedCommands: String { language == .chinese ? "固定命令与合盖动作" : "Fixed Commands And Lid Action" }

    var verification: String { language == .chinese ? "验证" : "Verification" }
    var runChecks: String { language == .chinese ? "运行检查" : "Run Checks" }
    var noVerification: String { language == .chinese ? "还没有运行验证。" : "No verification has been run yet." }
    var rustDeskCompatibility: String { language == .chinese ? "RustDesk 兼容" : "RustDesk Compatibility" }
    var fixRustDesk: String { language == .chinese ? "修复 RustDesk" : "Fix RustDesk" }
    var restartRustDesk: String { language == .chinese ? "重启 RustDesk" : "Restart RustDesk" }
    var rustDeskCompatible: String {
        language == .chinese
            ? "RustDesk 已允许显示器睡眠，当前也没有拦截显示器睡眠。"
            : "RustDesk allows display sleep and is not currently blocking it."
    }
    var rustDeskBlocksDisplaySleep: String {
        language == .chinese
            ? "RustDesk 正在阻止显示器睡眠。可写入官方高级设置，让远程会话不再强制常亮屏幕。"
            : "RustDesk is preventing display sleep. Apply the official advanced settings so remote sessions no longer force the display awake."
    }
    var rustDeskNeedsRestart: String {
        language == .chinese
            ? "RustDesk 配置已修复，但正在运行的会话仍持有拦截；重启 RustDesk 后生效。"
            : "RustDesk is configured, but the running session still holds a blocker. Restart RustDesk to apply it."
    }
    var rustDeskFixApplied: String {
        language == .chinese
            ? "已写入 RustDesk 配置并创建备份。请重启 RustDesk，让当前会话释放显示器睡眠拦截。"
            : "RustDesk config was updated and backed up. Restart RustDesk so the current session releases the display sleep blocker."
    }
    var rustDeskAlreadyConfigured: String {
        language == .chinese
            ? "RustDesk 配置已经是兼容状态。若仍显示拦截，请重启 RustDesk。"
            : "RustDesk is already configured. If a blocker remains, restart RustDesk."
    }
    var rustDeskRestarted: String {
        language == .chinese
            ? "RustDesk 已重启；请重新连接后再运行检查。"
            : "RustDesk restarted. Reconnect, then run checks again."
    }
    var recentEvents: String { language == .chinese ? "最近事件" : "Recent Events" }
    var noEvents: String {
        language == .chinese
            ? "开启、关闭和安全回滚会记录在这里。"
            : "Mode changes and safety actions will appear here."
    }

    func eventMessage(_ message: String) -> String {
        guard language == .chinese else { return message }
        switch message {
        case WorkstationEventMessage.enabledOnAC:
            return "已在接电状态开启工作站模式。"
        case WorkstationEventMessage.disabledAndRestored:
            return "已关闭工作站模式并恢复睡眠策略。"
        case WorkstationEventMessage.closedLidDisplaySleepRequested:
            return "检测到合盖，已请求熄灭显示器，工作站模式保持开启。"
        default:
            return message
        }
    }

    func verificationTitle(_ title: String) -> String {
        guard language == .chinese else { return title }
        switch title {
        case "AC Power": return "电源已接入"
        case "System Sleep Disabled": return "系统睡眠禁止"
        case "AC Idle Sleep": return "接电空闲睡眠"
        case "Display Sleep Blockers": return "显示器睡眠拦截"
        case "Privileged Helper": return "受保护 Helper"
        default: return title
        }
    }

    func verificationDetail(_ detail: String) -> String {
        guard language == .chinese else { return detail }
        if detail.contains("Power adapter is connected") {
            return "已接入电源；是否正在充电不影响此模式。"
        }
        if detail.contains("SleepDisabled is off") {
            return "SleepDisabled 关闭，合盖后仍可能睡眠。"
        }
        if detail.contains("SleepDisabled is active") {
            return "SleepDisabled 已开启，可保护合盖运行。"
        }
        if detail.contains("AC idle system sleep is disabled") {
            return "接电时空闲系统睡眠已关闭。"
        }
        if detail.contains("AC idle system sleep is not disabled") {
            return "接电空闲睡眠未关闭。"
        }
        if detail.contains("No app is currently preventing display sleep") {
            return "当前没有 App 阻止显示器睡眠。"
        }
        if detail.contains("These apps are preventing display sleep") {
            return detail
                .replacingOccurrences(of: "These apps are preventing display sleep: ", with: "这些 App 正在阻止显示器睡眠：")
                .replacingOccurrences(of: ".", with: "。")
        }
        if detail.contains("Helper is installed") {
            return "Helper 已安装，可执行固定受保护命令。"
        }
        if detail.contains("Helper is unavailable") {
            return "Helper 当前不可用；本地开发版会改用管理员授权执行固定命令。"
        }
        if detail.contains("Helper is not installed") {
            return "Helper 未安装，当前只能读取状态。"
        }
        return detail
    }
}
