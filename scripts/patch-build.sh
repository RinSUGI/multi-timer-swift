#!/usr/bin/env bash
# パッチバージョンを上げて Universal DMG をビルドする。
# 旧 Electron 版の scripts/patch-build.sh に相当。
#
# 使い方:
#   ./scripts/patch-build.sh          # patch を +1（例: 1.0.4 → 1.0.5）
#   ./scripts/patch-build.sh minor    # minor を +1（例: 1.0.4 → 1.1.0）
#   ./scripts/patch-build.sh major    # major を +1（例: 1.0.4 → 2.0.0）
#
# バージョンを管理しているファイル（3か所）をまとめて更新する:
#   Sources/MultiTimerCore/Constants.swift
#   scripts/Info.plist
#   scripts/build-app.sh
set -euo pipefail

BUMP="${1:-patch}"

# ---------- 現在のバージョンを読む ----------
CURRENT=$(grep 'appVersion' Sources/MultiTimerCore/Constants.swift \
  | sed 's/.*"\(.*\)".*/\1/')
echo "==> Current version: ${CURRENT}"

IFS='.' read -r MAJOR MINOR PATCH <<< "${CURRENT}"

case "${BUMP}" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
  *)
    echo "Usage: $0 [patch|minor|major]" >&2
    exit 1
    ;;
esac

NEW="${MAJOR}.${MINOR}.${PATCH}"
echo "==> New version:     ${NEW}"

# ---------- 3か所を更新 ----------
# Constants.swift
sed -i '' "s/appVersion = \"${CURRENT}\"/appVersion = \"${NEW}\"/" \
  Sources/MultiTimerCore/Constants.swift

# Info.plist（CFBundleShortVersionString）
sed -i '' "/<key>CFBundleShortVersionString<\/key>/{n;s/<string>${CURRENT}<\/string>/<string>${NEW}<\/string>/;}" \
  scripts/Info.plist

# build-app.sh（VERSION= 行）
sed -i '' "s/^VERSION=\"${CURRENT}\"/VERSION=\"${NEW}\"/" \
  scripts/build-app.sh

echo "==> Updated version in:"
echo "    Sources/MultiTimerCore/Constants.swift"
echo "    scripts/Info.plist"
echo "    scripts/build-app.sh"

# ---------- ビルド ----------
echo ""
./scripts/build-app.sh

# ---------- 動作確認 ----------
DMG_PATH="dist/Multi Timer-${NEW}-universal.dmg"
APP_BUNDLE="dist/Multi Timer.app"

echo ""
echo "==> Opening app for verification..."
open -n "${APP_BUNDLE}"

# ---------- チェックサム ----------
echo ""
echo "==> SHA-256 checksum"
shasum -a 256 "${DMG_PATH}" | tee dist/sha-256.txt

echo ""
echo "==> Done: ${DMG_PATH}"
echo "    Checksum saved to: dist/sha-256.txt"
