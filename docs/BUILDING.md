# Build And Release Notes

Remote Workstation is currently distributed as a local development build. The
DMG script creates a convenient installer image, but it does not imply Developer
ID signing or notarization.

## Requirements

- macOS 13 or newer
- Xcode command line tools or Xcode
- Swift 6 compatible toolchain
- ImageMagick (`magick`) for compiling the SVG icon into `.icns`
- `iconutil` and `hdiutil`, included with macOS

Install ImageMagick with Homebrew:

```zsh
brew install imagemagick
```

## Test

```zsh
swift test
```

## Build The Local App Bundle

```zsh
Packaging/Scripts/build-local-app.sh
```

Output:

```text
.build/app/RemoteWorkstation.app
```

The script also compiles `Design/remote-workstation-icon.svg` into:

```text
.build/app/RemoteWorkstation.app/Contents/Resources/RemoteWorkstation.icns
```

## Build The DMG

```zsh
Packaging/Scripts/build-dmg.sh
```

Output:

```text
.build/dist/RemoteWorkstation-<version>.dmg
.build/dist/RemoteWorkstation-<version>.dmg.sha256
```

The DMG contains:

- `RemoteWorkstation.app`
- An `Applications` symlink
- `LICENSE`
- A short `README-FIRST.txt` warning

## Optional Code Signing

For local unsigned testing, no identity is required.

For a signed local build:

```zsh
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  Packaging/Scripts/build-dmg.sh
```

Notarization is not implemented yet. A public release should add Developer ID
signing, notarization, staple verification, and a clean uninstall path.

## Pre-Publish Privacy Check

Before publishing source code:

```zsh
git status --short
rg -n -uu "PRIVATE KEY|github_pat_|ghp_|sk-|password|secret|token|/Users/" .
```

Do not publish `.build/`, local RustDesk configuration, state files, `.env`
files, local app bundles, DMGs, or unrelated private repositories.

