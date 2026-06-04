#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="$ROOT/.build/app/RemoteWorkstation.app"
DIST_DIR="$ROOT/.build/dist"
DMG_WORK_DIR="$ROOT/.build/dmg"
STAGING_DIR="$DMG_WORK_DIR/RemoteWorkstation"

"$ROOT/Packaging/Scripts/build-local-app.sh"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist")"
DMG_PATH="$DIST_DIR/RemoteWorkstation-$VERSION.dmg"

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  codesign --force --deep --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$APP_DIR"
fi

rm -rf "$DMG_WORK_DIR"
mkdir -p "$STAGING_DIR" "$DIST_DIR"

ditto "$APP_DIR" "$STAGING_DIR/RemoteWorkstation.app"
ln -s /Applications "$STAGING_DIR/Applications"

if [[ -f "$ROOT/LICENSE" ]]; then
  cp "$ROOT/LICENSE" "$STAGING_DIR/LICENSE"
fi

cat > "$STAGING_DIR/README-FIRST.txt" <<'TEXT'
Remote Workstation is experimental software.

It changes macOS sleep behavior while workstation mode is enabled. Test it on
your own hardware before relying on it for real work.

If anything looks wrong, disable the mode in the app or run:

sudo pmset disablesleep 0
sudo pmset -c sleep 1 displaysleep 10 disksleep 10 womp 1 tcpkeepalive 1

This build is provided as-is, without warranty.

---

远程工作站仍处于测试阶段。

它会在工作站模式开启时修改 macOS 睡眠行为。请先在自己的硬件上测试，
不要直接把它用于无法中断的重要任务。

如果状态不对，请先在 App 中关闭模式，或手动执行：

sudo pmset disablesleep 0
sudo pmset -c sleep 1 displaysleep 10 disksleep 10 womp 1 tcpkeepalive 1

本构建按现状提供，不提供任何可用性担保。
TEXT

rm -f "$DMG_PATH" "$DMG_PATH.sha256"
hdiutil create \
  -volname "Remote Workstation" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"

echo "$DMG_PATH"
