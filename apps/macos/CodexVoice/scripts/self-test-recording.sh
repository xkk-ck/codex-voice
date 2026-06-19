#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_BUNDLE="$APP_ROOT/dist/Codex Voice.app"
SECONDS_TO_RECORD="${1:-15}"

"$SCRIPT_DIR/build-app.sh" >/tmp/codex-voice-build.log

pkill -f '/Codex Voice.app/Contents/MacOS/CodexVoice' >/dev/null 2>&1 || true

before="$(ls -t "$HOME"/Library/Logs/DiagnosticReports/CodexVoice-*.ips 2>/dev/null | head -1 || true)"

open -W "$APP_BUNDLE" --args --self-test-record "$SECONDS_TO_RECORD" \
  >/tmp/codex-voice-self-test.log 2>&1 &
open_pid="$!"

sleep 4
if ! pgrep -fl "CodexVoice.*--self-test-record" >/dev/null 2>&1; then
  echo "Codex Voice did not stay running after self-test launch." >&2
  cat /tmp/codex-voice-self-test.log >&2 || true
  exit 1
fi

deadline=$((SECONDS + SECONDS_TO_RECORD + 10))
while kill -0 "$open_pid" >/dev/null 2>&1; do
  if (( SECONDS >= deadline )); then
    pkill -f '/Codex Voice.app/Contents/MacOS/CodexVoice' >/dev/null 2>&1 || true
    break
  fi
  sleep 1
done

wait "$open_pid" || true

after="$(ls -t "$HOME"/Library/Logs/DiagnosticReports/CodexVoice-*.ips 2>/dev/null | head -1 || true)"
if [[ "$before" != "$after" ]]; then
  echo "Codex Voice crashed during recording self-test: $after" >&2
  grep -n "triggered\\|VoiceRecognizer\\|exception\\|termination\\|queue\\|TCC" "$after" | head -100 >&2 || true
  exit 1
fi

echo "Recording self-test passed for ${SECONDS_TO_RECORD}s."
