#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Building Wrangler (release mode)..."
cd "${ROOT_DIR}"
swift build -c release --product Wrangler

VERSION="${1:-1.4.0}"
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
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
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
SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development" | head -n 1 | awk -F '"' '{print $2}' || true)

if [ -n "${SIGNING_IDENTITY}" ]; then
    echo "    Using Keychain certificate: ${SIGNING_IDENTITY}"
    codesign --force --deep --sign "${SIGNING_IDENTITY}" "${APP_DIR}"
else
    echo "    Using ad-hoc signature (-)"
    codesign --force --deep --sign - --identifier "com.rngo.wrangler" "${APP_DIR}"
fi

echo "==> Wrangler.app assembled successfully at ${APP_DIR}!"
echo "    To launch: open ${APP_DIR}"
