#!/usr/bin/env bash
set -euo pipefail

VERSION="1.1.0"
APP_NAME="Multi Timer"
BUNDLE_NAME="multi-timer"
DIST="dist"
APP_BUNDLE="${DIST}/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}-universal.dmg"
DMG_PATH="${DIST}/${DMG_NAME}"

echo "==> Cleaning dist/"
rm -rf "${DIST}"
mkdir -p "${DIST}"

echo "==> Building Universal binary (arm64 + x86_64)"
swift build -c release --arch arm64 --arch x86_64

BINARY_PATH=".build/apple/Products/Release/${BUNDLE_NAME}"

echo "==> Assembling .app bundle"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BINARY_PATH}" "${APP_BUNDLE}/Contents/MacOS/${BUNDLE_NAME}"
cp "scripts/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
cp "Sources/MultiTimerApp/Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
cp "Sources/MultiTimerApp/Resources/chime.caf" "${APP_BUNDLE}/Contents/Resources/chime.caf"

# SwiftPM generates a resource bundle for targets that declare `resources:`.
# `Bundle.module` hard-crashes (fatalError) at launch if this bundle is missing,
# so it must be copied into the .app alongside the flattened resources.
RESOURCE_BUNDLE=".build/apple/Products/Release/${BUNDLE_NAME}_MultiTimerApp.bundle"
cp -R "${RESOURCE_BUNDLE}" "${APP_BUNDLE}/Contents/Resources/"

echo "==> Signing (ad-hoc)"
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> Creating DMG (drag-to-Applications installer layout)"
STAGING="${DIST}/dmg-staging"
TMP_DMG="${DIST}/tmp.dmg"
MOUNT_DIR="/Volumes/${APP_NAME}"

# Clean up any leftovers from a previous/interrupted run.
hdiutil detach "${MOUNT_DIR}" >/dev/null 2>&1 || true
rm -rf "${STAGING}" "${TMP_DMG}"
mkdir -p "${STAGING}/.background"

# Contents shown in the DMG window: the app and a shortcut to /Applications.
cp -R "${APP_BUNDLE}" "${STAGING}/"
ln -s /Applications "${STAGING}/Applications"

# Render the background at 1x + 2x and combine into a hi-DPI TIFF (crisp on Retina).
swift scripts/render-dmg-background.swift "${STAGING}/.background/background.png" 1
swift scripts/render-dmg-background.swift "${STAGING}/.background/background@2x.png" 2
tiffutil -cathidpicheck \
  "${STAGING}/.background/background.png" \
  "${STAGING}/.background/background@2x.png" \
  -out "${STAGING}/.background/background.tiff"
rm -f "${STAGING}/.background/background.png" "${STAGING}/.background/background@2x.png"

# Writable image so Finder can persist the window layout into .DS_Store.
hdiutil create -srcfolder "${STAGING}" -volname "${APP_NAME}" \
  -fs HFS+ -format UDRW -ov "${TMP_DMG}" >/dev/null
hdiutil attach "${TMP_DMG}" -readwrite -noverify -noautoopen >/dev/null
sleep 2

osascript scripts/dmg-layout.applescript "${APP_NAME}" "${APP_NAME}.app"

# Hide the background folder and drop the volume-housekeeping directories so the
# installer window stays clean. (The layout script already parks .background
# below the visible area; the invisible flag is belt-and-suspenders.)
SetFile -a V "${MOUNT_DIR}/.background" 2>/dev/null || chflags hidden "${MOUNT_DIR}/.background"
rm -rf "${MOUNT_DIR}/.fseventsd" "${MOUNT_DIR}/.Trashes"
sync

hdiutil detach "${MOUNT_DIR}" >/dev/null

# Compress to the final read-only distributable image.
rm -f "${DMG_PATH}"
hdiutil convert "${TMP_DMG}" -format UDZO -imagekey zlib-level=9 -o "${DMG_PATH}" >/dev/null

rm -rf "${STAGING}" "${TMP_DMG}"

echo "==> SHA-256 checksum"
shasum -a 256 "${DMG_PATH}"

echo "==> Done: ${DMG_PATH}"
