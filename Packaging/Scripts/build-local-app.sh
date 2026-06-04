#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="$ROOT/.build/app/RemoteWorkstation.app"
ICON_SOURCE="$ROOT/Design/remote-workstation-icon.svg"
ICON_BUILD_DIR="$ROOT/.build/app-icon"
ICONSET_DIR="$ICON_BUILD_DIR/RemoteWorkstation.iconset"
ICON_FILE="$ICON_BUILD_DIR/RemoteWorkstation.icns"

cd "$ROOT"
swift build

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
mkdir -p "$APP_DIR/Contents/Library/LaunchDaemons"

cp "$ROOT/.build/debug/RemoteWorkstationApp" "$APP_DIR/Contents/MacOS/RemoteWorkstationApp"
cp "$ROOT/.build/debug/RemoteWorkstationHelper" "$APP_DIR/Contents/MacOS/RemoteWorkstationHelper"
cp "$ROOT/Packaging/LaunchDaemons/com.codex.remote-workstation.helper.plist" \
  "$APP_DIR/Contents/Library/LaunchDaemons/com.codex.remote-workstation.helper.plist"

if [[ -f "$ICON_SOURCE" ]]; then
  if ! command -v magick >/dev/null 2>&1; then
    echo "error: ImageMagick 'magick' is required to compile $ICON_SOURCE into .icns" >&2
    exit 1
  fi
  rm -rf "$ICON_BUILD_DIR"
  mkdir -p "$ICONSET_DIR"

  magick "$ICON_SOURCE" -resize 16x16 "$ICONSET_DIR/icon_16x16.png"
  magick "$ICON_SOURCE" -resize 32x32 "$ICONSET_DIR/icon_16x16@2x.png"
  magick "$ICON_SOURCE" -resize 32x32 "$ICONSET_DIR/icon_32x32.png"
  magick "$ICON_SOURCE" -resize 64x64 "$ICONSET_DIR/icon_32x32@2x.png"
  magick "$ICON_SOURCE" -resize 128x128 "$ICONSET_DIR/icon_128x128.png"
  magick "$ICON_SOURCE" -resize 256x256 "$ICONSET_DIR/icon_128x128@2x.png"
  magick "$ICON_SOURCE" -resize 256x256 "$ICONSET_DIR/icon_256x256.png"
  magick "$ICON_SOURCE" -resize 512x512 "$ICONSET_DIR/icon_256x256@2x.png"
  magick "$ICON_SOURCE" -resize 512x512 "$ICONSET_DIR/icon_512x512.png"
  magick "$ICON_SOURCE" -resize 1024x1024 "$ICONSET_DIR/icon_512x512@2x.png"
  iconutil -c icns "$ICONSET_DIR" -o "$ICON_FILE"
  cp "$ICON_FILE" "$APP_DIR/Contents/Resources/RemoteWorkstation.icns"
fi

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>RemoteWorkstationApp</string>
	<key>CFBundleIdentifier</key>
	<string>com.codex.remote-workstation</string>
	<key>CFBundleDisplayName</key>
	<string>远程工作站</string>
	<key>CFBundleName</key>
	<string>远程工作站</string>
	<key>CFBundleIconFile</key>
	<string>RemoteWorkstation</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>0.1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
PLIST

echo "$APP_DIR"
