#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_BUNDLE="$APP_ROOT/dist/Codex Voice.app"
SECONDS_TO_RECORD="${1:-15}"
ALLOW_PERMISSION_NEEDED="${2:-}"

"$SCRIPT_DIR/build-app.sh" >/tmp/codex-voice-build.log

pkill -f '/Codex Voice.app/Contents/MacOS/CodexVoice' >/dev/null 2>&1 || true

before="$(ls -t "$HOME"/Library/Logs/DiagnosticReports/CodexVoice-*.ips 2>/dev/null | head -1 || true)"
status_file="$(mktemp "${TMPDIR:-/tmp}/codex-voice-status.XXXXXX")"

CODEX_VOICE_SELF_TEST_STATUS="$status_file" open -W "$APP_BUNDLE" --args --self-test-record "$SECONDS_TO_RECORD" \
  >/tmp/codex-voice-self-test.log 2>&1 &
open_pid="$!"

sleep 4
if ! pgrep -fl "CodexVoice.*--self-test-record" >/dev/null 2>&1; then
  echo "Codex Voice did not stay running after self-test launch." >&2
  cat /tmp/codex-voice-self-test.log >&2 || true
  exit 1
fi

listening_deadline=$((SECONDS + 40))
while true; do
  if [[ "$(cat "$status_file" 2>/dev/null || true)" == "listening" ]]; then
    break
  fi
  if (( SECONDS >= listening_deadline )); then
    last_status="$(cat "$status_file" 2>/dev/null || echo '<none>')"
    if [[ "$ALLOW_PERMISSION_NEEDED" == "--allow-permission-needed" ]] && [[ "$last_status" == *"语音识别权限"* || "$last_status" == *"Speech Recognition"* ]]; then
      pkill -f '/Codex Voice.app/Contents/MacOS/CodexVoice' >/dev/null 2>&1 || true
      wait "$open_pid" || true
      echo "Permission-needed self-test passed: $last_status"
      exit 0
    fi

    echo "Codex Voice did not enter listening state." >&2
    echo "Last status: $last_status" >&2
    pkill -f '/Codex Voice.app/Contents/MacOS/CodexVoice' >/dev/null 2>&1 || true
    wait "$open_pid" || true
    exit 1
  fi
  sleep 1
done

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
