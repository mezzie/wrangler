#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

VERSION="${1:-1.9.3}"
APP_PATH="${ROOT_DIR}/build/Wrangler.app"
DMG_PATH="${ROOT_DIR}/build/Wrangler-${VERSION}.dmg"
STAGING_DIR="${ROOT_DIR}/build/dmg-staging"

echo "==> Ensuring Wrangler.app is built..."
"${SCRIPT_DIR}/build-app.sh" "${VERSION}"

echo "==> Preparing DMG staging area..."
rm -rf "${STAGING_DIR}" "${DMG_PATH}"
mkdir -p "${STAGING_DIR}"

cp -R "${APP_PATH}" "${STAGING_DIR}/Wrangler.app"
ln -s /Applications "${STAGING_DIR}/Applications"

if [ -f "${APP_PATH}/Contents/Resources/AppIcon.icns" ]; then
    cp "${APP_PATH}/Contents/Resources/AppIcon.icns" "${STAGING_DIR}/.VolumeIcon.icns"
fi

echo "==> Creating compressed disk image: ${DMG_PATH}..."
hdiutil create \
    -volname "Wrangler" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

rm -rf "${STAGING_DIR}"

# Sign DMG if certificate exists
SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -n 1 | awk -F '"' '{print $2}' || true)
if [ -z "${SIGNING_IDENTITY}" ]; then
    SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development" | head -n 1 | awk -F '"' '{print $2}' || true)
fi

if [ -n "${SIGNING_IDENTITY}" ]; then
    echo "==> Signing DMG with ${SIGNING_IDENTITY}..."
    codesign --force --sign "${SIGNING_IDENTITY}" "${DMG_PATH}" || true
fi

# Notarize DMG if notarytool credentials profile exists
if xcrun notarytool history --keychain-profile "wrangler-notary" >/dev/null 2>&1; then
    echo "==> Submitting DMG to Apple for Notarization..."
    xcrun notarytool submit "${DMG_PATH}" --keychain-profile "wrangler-notary" --wait
    echo "==> Stapling notarization ticket to DMG..."
    xcrun stapler staple "${DMG_PATH}"
fi

# Create unversioned symlink for convenience
cp "${DMG_PATH}" "${ROOT_DIR}/build/Wrangler.dmg"

echo "==> DMG created successfully at:"
echo "    ${DMG_PATH}"
echo "    ${ROOT_DIR}/build/Wrangler.dmg"
