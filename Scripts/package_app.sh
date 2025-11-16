#!/usr/bin/env bash
set -euo pipefail
CONF=${1:-debug}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

swift build -c "$CONF"
APP="$ROOT/Trimmy.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# Convert .icon (macOS 15 IconStudio format) to .icns if present
ICON_SOURCE="$ROOT/Icon.icon"
ICON_TARGET="$ROOT/Icon.icns"
if [[ -f "$ICON_SOURCE" ]]; then
  iconutil --convert icns --output "$ICON_TARGET" "$ICON_SOURCE"
fi

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Trimmy</string>
    <key>CFBundleDisplayName</key><string>Trimmy</string>
    <key>CFBundleIdentifier</key><string>com.example.trimmy</string>
    <key>CFBundleExecutable</key><string>Trimmy</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>15.0</string>
    <key>LSUIElement</key><true/>
    <key>CFBundleIconFile</key><string>Icon</string>
    <key>NSHumanReadableCopyright</key><string>© 2025 Peter Steinberger. MIT License.</string>
</dict>
</plist>
PLIST

cp ".build/$CONF/Trimmy" "$APP/Contents/MacOS/Trimmy"
chmod +x "$APP/Contents/MacOS/Trimmy"
# Icon
if [[ -f "$ICON_TARGET" ]]; then
  cp "$ICON_TARGET" "$APP/Contents/Resources/Icon.icns"
fi

echo "Created $APP"
