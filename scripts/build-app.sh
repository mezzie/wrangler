#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Building Wrangler (release mode)..."
cd "${ROOT_DIR}"
swift build -c release --product Wrangler

BIN_PATH="${ROOT_DIR}/.build/release/Wrangler"
APP_DIR="${ROOT_DIR}/build/Wrangler.app"

echo "==> Packaging ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "${BIN_PATH}" "${APP_DIR}/Contents/MacOS/Wrangler"

cat << 'EOF' > "${APP_DIR}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Wrangler</string>
    <key>CFBundleIdentifier</key>
    <string>com.rngo.wrangler</string>
    <key>CFBundleName</key>
    <string>Wrangler</string>
    <key>CFBundleDisplayName</key>
    <string>Wrangler</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

echo "==> Code-signing ${APP_DIR}..."
codesign --force --deep --sign - --identifier "com.rngo.wrangler" "${APP_DIR}"

echo "==> Wrangler.app assembled successfully at ${APP_DIR}!"
echo "    To launch: open ${APP_DIR}"
