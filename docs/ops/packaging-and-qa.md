# Packaging And QA

## Local Development

```zsh
swift build
swift test
swift run RemoteWorkstationApp
```

## Privileged Helper Packaging

The code contains the helper executable and `SMAppService` registration boundary. A production `.app` bundle must include:

- Main app under `RemoteWorkstation.app/Contents/MacOS/RemoteWorkstationApp`.
- Helper executable under a signed bundle-relative location.
- LaunchDaemon plist at `RemoteWorkstation.app/Contents/Library/LaunchDaemons/com.codex.remote-workstation.helper.plist`.
- Plist using `BundleProgram` so relocation is supported.
- Matching code-signing requirements between the main app and helper.

The template plist lives at `Packaging/LaunchDaemons/com.codex.remote-workstation.helper.plist`.

`SMAppService.daemon(plistName:)` expects the containing app to live somewhere accessible before login. `/Applications` is recommended for final distribution.

## Local SwiftPM Limitation

`swift run RemoteWorkstationApp` is useful for UI and read-only status work, but a SwiftPM executable is not the final `.app` bundle layout required by `SMAppService`. For privileged mode, package the app bundle first, then install the helper through the in-app flow.

## Manual Closed-Lid QA

1. Connect power.
2. Confirm `pmset -g batt` reports `Now drawing from 'AC Power'`.
3. Enable Remote Workstation Mode.
4. Confirm `pmset -g live` reports `SleepDisabled 1`.
5. Run verification and confirm no unexpected display-sleep blockers are listed.
6. Start a visible long-running command, such as writing timestamps to a temp file.
7. Connect through RustDesk.
8. Close lid and confirm the app/helper requests `pmset displaysleepnow`.
9. Reconnect after 10 minutes and confirm the command kept running.
10. Repeat for 30 minutes.
11. Disable mode and confirm `SleepDisabled 0`.

If RustDesk or another remote tool holds `PreventUserIdleDisplaySleep`, the machine can remain awake correctly while the display may resist sleeping. The app surfaces these blockers in verification so this conflict is visible.

## Troubleshooting

Inspect current state:

```zsh
pmset -g batt
pmset -g live
pmset -g assertions
ioreg -r -k AppleClamshellCausesSleep -d 1 | rg "AppleClamshell|SleepDisabled"
```

Rollback:

```zsh
sudo pmset disablesleep 0
sudo pmset -c sleep 1 displaysleep 10 disksleep 10 womp 1 tcpkeepalive 1
```
