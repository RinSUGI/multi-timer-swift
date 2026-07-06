#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.4"
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

echo "==> Signing (ad-hoc)"
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> Creating DMG"
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${APP_BUNDLE}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

echo "==> SHA-256 checksum"
shasum -a 256 "${DMG_PATH}"

echo "==> Done: ${DMG_PATH}"
