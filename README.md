<p align="center">
  <img src="Design/remote-workstation-icon.svg" width="128" alt="Remote Workstation logo">
</p>

<h1 align="center">Remote Workstation</h1>

<p align="center">
  A quiet native macOS tool for keeping a plugged-in MacBook reachable while the lid is closed.
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-111111.svg"></a>
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-111111.svg">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6-111111.svg">
  <img alt="Status" src="https://img.shields.io/badge/status-experimental-orange.svg">
</p>

Remote Workstation is built for one specific moment: your MacBook is plugged in,
your long-running local work matters, and you want to close the lid without
losing access through RustDesk, Codex, Claude CLI, SSH, or a terminal session.

It is not a battery utility. Charge limiting belongs to macOS or tools such as
AlDente. This app only deals with sleep policy, verification, rollback, and a
visible trust surface.

## What It Does

- Shows whether the Mac is on AC power, even when charging is paused.
- Enables a fixed, auditable workstation power policy for AC power.
- Keeps system sleep disabled while workstation mode is active.
- Requests display sleep after the lid closes, so the machine can keep working
  without forcing the internal display to stay awake.
- Detects display-sleep blockers such as remote desktop apps.
- Applies RustDesk's documented keep-awake settings so RustDesk does not keep
  the display awake during remote sessions.
- Restores the previous AC power snapshot when the mode is disabled.

## Safety Model

The command plan is fixed. The app and helper do not accept arbitrary shell
commands.

Enable mode runs:

```zsh
/usr/bin/pmset -c sleep 0 displaysleep 1 disksleep 0 womp 1 tcpkeepalive 1
/usr/bin/pmset disablesleep 1
```

Closed-lid display sleep uses:

```zsh
/usr/bin/pmset displaysleepnow
```

Disable mode restores the saved AC snapshot and always runs:

```zsh
/usr/bin/pmset disablesleep 0
```

## Current Status

This project is experimental and under active testing. It is designed for local
technical users who understand macOS power management and can verify their own
hardware behavior.

The app does not guarantee that every Mac, macOS version, remote desktop tool,
dock, monitor, battery mode, or thermal condition will behave correctly. Use it
only after reading the rollback steps and testing on your own machine.

## Quick Start

Requirements:

- macOS 13 or newer
- Swift toolchain / Xcode command line tools
- ImageMagick for app icon compilation
- `hdiutil` and `iconutil`, included with macOS

Build and test:

```zsh
swift test
Packaging/Scripts/build-local-app.sh
open .build/app/RemoteWorkstation.app
```

Build a local DMG:

```zsh
Packaging/Scripts/build-dmg.sh
```

The DMG is written to `.build/dist/`.

## Manual Rollback

If anything looks wrong, disable workstation mode in the app first. If you need
to recover manually:

```zsh
sudo pmset disablesleep 0
sudo pmset -c sleep 1 displaysleep 10 disksleep 10 womp 1 tcpkeepalive 1
pmset -g live
pmset -g batt
```

## Privacy

Remote Workstation does not send telemetry, does not store passwords, and does
not connect to a network service. Local state is used for mode status, command
snapshots, verification results, and recent events.

Never publish your local RustDesk configuration, app state, build output, DMG
artifacts, or unrelated local repositories. The root `.gitignore` is set up to
exclude those files.

## Documentation

- [中文说明](docs/README.zh-CN.md)
- [Build and release notes](docs/BUILDING.md)
- [中文构建说明](docs/BUILDING.zh-CN.md)
- [Packaging and QA](docs/ops/packaging-and-qa.md)
- [Architecture decision](docs/decisions/ADR-001-native-macos-helper.md)

## Disclaimer

This software is provided as-is, without warranty. It is not guaranteed to work
on every system and may affect sleep behavior, remote connectivity, power use,
thermal state, or running work. The authors and contributors are not liable for
legal responsibility, data loss, hardware damage, service interruption, missed
work, financial loss, or any other damage arising from use of this project.

## License

MIT. See [LICENSE](LICENSE).

