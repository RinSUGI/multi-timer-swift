#!/usr/bin/env bash
# Dev-only launcher: builds the debug binary and wraps it in a minimal .app
# bundle so macOS launches it as a proper GUI app (Dock icon + focused window).
#
# `swift run multi-timer` compiles and runs the bare executable, but a SwiftUI
# app started outside an .app bundle has no activation policy, so its window
# never comes to the front — it looks like nothing launched. This wraps the
# debug binary and `open`s it instead. Fast; no release/universal/DMG build.
set -euo pipefail

BUNDLE_NAME="multi-timer"
APP_NAME="Multi Timer (dev)"
BUILD_DIR=".build/debug"
APP_BUNDLE=".build/${APP_NAME}.app"

echo "==> Building debug binary"
swift build

echo "==> Assembling ${APP_BUNDLE}"
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${BUNDLE_NAME}" "${APP_BUNDLE}/Contents/MacOS/${BUNDLE_NAME}"
cp "scripts/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# Bundle.module hard-crashes at launch if the SwiftPM resource bundle is missing.
cp -R "${BUILD_DIR}/${BUNDLE_NAME}_MultiTimerApp.bundle" "${APP_BUNDLE}/Contents/Resources/"
cp "Sources/MultiTimerApp/Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns" 2>/dev/null || true

codesign --force --deep --sign - "${APP_BUNDLE}" >/dev/null 2>&1 || true

echo "==> Launching"
# Relaunch cleanly each time so code changes are picked up.
pkill -f "${APP_BUNDLE}/Contents/MacOS/${BUNDLE_NAME}" 2>/dev/null || true
open -n "${APP_BUNDLE}"
echo "==> Launched ${APP_BUNDLE}"
