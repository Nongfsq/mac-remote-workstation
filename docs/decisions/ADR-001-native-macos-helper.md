# ADR-001: Native macOS App With Privileged Helper

## Status

Accepted for V1.

## Context

The product controls macOS sleep behavior for a personal MacBook used as a temporary remote workstation. The central operation requires privileged `pmset` writes and must be safe, auditable, and reversible.

## Decision

Build a native macOS application with SwiftUI for the visible trust surface and a privileged helper installed with `SMAppService.daemon(plistName:)` for root-only power commands.

The helper exposes a fixed command contract:

- `getStatus`
- `enableWorkstationMode`
- `disableWorkstationMode`
- `restoreSnapshot`
- `runVerification`

It never accepts arbitrary command strings.

## Rejected Alternatives

- Menu bar app: hides risk and encourages casual toggling.
- Shell script with sudo: works for the owner but fails the product promise of explicit state, rollback, and verification.
- Electron app: unnecessary runtime and weaker native helper fit.
- Pure `caffeinate`: does not sufficiently address the closed-lid sleep path.
- Battery app integration: confuses charge limiting with sleep management.

## Consequences

- Requires code signing and bundle packaging for production helper registration.
- Makes the privilege boundary explicit.
- Keeps the main app comprehensible, testable, and native.
- Allows future notarized distribution without rethinking the core architecture.
