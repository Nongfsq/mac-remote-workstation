# macOS Remote Workstation PM

## Problem And Intent

The user wants a MacBook to behave like a temporary plugged-in remote workstation: close the lid, keep RustDesk/Codex/Claude CLI reachable, and avoid accidental sleep while work is running. The product must not depend on battery apps such as AlDente because charge limiting and sleep policy are separate systems.

## Target User

- A technical owner using a personal MacBook as a local always-near machine.
- Primary remote workflows: RustDesk, Codex, Claude CLI, terminal sessions, and long-running local jobs.
- Expected operating mode: enabled only while connected to AC Power.

## Product Judgment

The essential promise is trust: one obvious switch that makes the machine reachable, shows exactly why it is safe, and rolls back when the user is done or power is disconnected.

This should feel like a system control panel, not a cute utility. The user should see AC state, sleep state, closed-lid risk, helper status, planned commands, and verification results in one full window. A menu bar-first app would hide the most important risk.

## Proposed Behavior

- Read and show current AC/Battery state; treat `AC attached; not charging` as valid AC Power.
- Enable only on AC Power.
- On enable, snapshot current AC power settings, set fixed remote workstation settings, and optionally sleep the display.
- On disable, restore the snapshot and always run `pmset disablesleep 0`.
- Monitor failsafe conditions in the helper: AC disconnect and low battery threshold.
- Keep battery charge tools out of the product contract.

## Non-Goals

- No AlDente replacement.
- No charge limiting, discharge management, or battery calibration.
- No network telemetry.
- No arbitrary shell command runner.
- No App Store-first distribution for V1.
- No menu bar-first control surface.

## Success Criteria

- The app can explain whether closed-lid remote mode is currently safe.
- The user can enable, disable, verify, and recover without copying commands.
- Tests prove the parser treats AC attached but not charging as AC Power.
- Tests prove restore always disables `SleepDisabled`.
- Manual QA confirms RustDesk reconnects after 10-minute and 30-minute closed-lid trials.

## Risks

- `pmset disablesleep` is native but not a mainstream UI setting; system updates may change behavior.
- Closed-lid high-load work needs good ventilation.
- Privileged helper packaging requires careful signing and launchd plist placement.
- The app must never continue `SleepDisabled` after AC disconnect.
