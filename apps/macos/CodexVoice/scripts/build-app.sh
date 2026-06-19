#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$APP_ROOT/dist"
APP_BUNDLE="$DIST_DIR/Codex Voice.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

cd "$APP_ROOT"
swift build -c release

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"
cp ".build/release/CodexVoice" "$MACOS/CodexVoice"
cp "Resources/Info.plist" "$CONTENTS/Info.plist"
chmod +x "$MACOS/CodexVoice"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - --entitlements "Resources/CodexVoice.entitlements" "$APP_BUNDLE" >/dev/null
fi

echo "$APP_BUNDLE"
