# PLAN+TASK: macOS Remote Workstation App

## Summary

Build a full-window native macOS app that turns a plugged-in MacBook into a temporary closed-lid remote workstation for RustDesk, Codex, and Claude CLI. The app does not manage battery charging and is not menu bar-first.

## Current Reality

- Repository started empty.
- Development machine has Xcode 26.5 and Swift 6.3.2.
- The target Mac can be on AC Power while not charging due to battery limit tooling.
- `pmset` and IOKit expose the power state and sleep settings needed for V1.

## Architecture Decisions

- SwiftPM project for core code, tests, and local iteration.
- SwiftUI App target for the visible dashboard.
- Shared Core target for models, parsers, policy, and fixed command plans.
- Service target for command execution, persistence, status reading, helper service manager, and controller.
- Helper executable target for future LaunchDaemon packaging.
- `SMAppService.daemon(plistName:)` is the selected privileged helper registration mechanism.

## Tasks

- `MRW-001` Scaffold native macOS project: SwiftPM package, SwiftUI App, helper executable, shared targets, tests, README.
- `MRW-002` Implement status reader: AC/Battery, charging state, pmset custom/live values, `SleepDisabled`, clamshell state.
- `MRW-003` Implement helper install flow: `SMAppService` manager and UI status.
- `MRW-004` Implement command contract: typed helper commands and response model; no arbitrary command execution.
- `MRW-005` Implement enable mode: snapshot settings, require AC Power, set fixed AC sleep policy and `disablesleep 1`.
- `MRW-006` Implement disable/restore: restore snapshot and always run `disablesleep 0`.
- `MRW-007` Implement failsafe boundary: helper command can enforce AC/low-battery disable; launchd timer/monitoring is packaging work.
- `MRW-008` Build main app UX: dashboard, toggle, status cards, verification panel, event log, settings copy.
- `MRW-009` Add verification workflow: local checks plus manual 10/30-minute closed-lid checklist.
- `MRW-010` Add tests and QA: parser, policy, command plan, mocked service tests.
- `MRW-011` Package and docs: rollback, troubleshooting, local build, future signing/notarization.

## Test And QA Plan

- Run `swift test`.
- Run `swift build`.
- Verify `pmset -g batt` output with AC attached but not charging is classified as AC Power.
- Verify restore command ordering.
- Manual hardware QA after packaging: enable on AC, close lid for 10 and 30 minutes, reconnect with RustDesk, then disable and inspect `pmset -g live`.

## Rollback

Manual rollback:

```zsh
sudo pmset disablesleep 0
sudo pmset -c sleep 1 displaysleep 10 disksleep 10 womp 1 tcpkeepalive 1
```

## Acceptance Criteria

- The package builds and tests pass.
- The app shows AC state, mode state, closed-lid risk, helper state, planned commands, verification, and event log.
- The helper/controller uses fixed command plans only.
- The product docs clearly state battery management is out of scope.
