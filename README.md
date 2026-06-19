# Codex Voice Plugin

[简体中文](./README.zh-CN.md)

Codex Voice is a lightweight voice input companion for Codex Desktop.

It adds a small microphone window that lets you speak naturally, review the transcript, and insert it into the Codex composer. On macOS it can use Accessibility automation to paste into Codex; if that permission is not available, it falls back to copying the transcript to the clipboard.

## MVP Decisions

- UI: small Chrome app-style mic window, not a regular browser tab or heavy desktop app.
- Speech recognition: browser Web Speech API, with Chinese or English selected automatically from the browser/system language.
- Insertion: macOS Accessibility automation first, clipboard fallback second.
- Auto-send: included in MVP, but disabled by default.
- Prompt refinement: use the current Codex thread first to avoid requiring an extra API key.

## Quick Start

### Browser MVP

```bash
./scripts/install-macos-helper-app
./scripts/open-codex-voice
```

This starts Codex Voice Helper and opens the mic window.

For a clearer macOS permission target, run `install-macos-helper-app` once and launch `Codex Voice Helper.app` from `~/Applications`.

For the full MVP guide, see [MVP Usage Guide](./docs/mvp-usage.md).

### Native macOS App Preview

Route A adds a lightweight SwiftUI app that uses Apple Speech Recognition instead of the browser Web Speech API:

```bash
./scripts/build-macos-app
open "apps/macos/CodexVoice/dist/Codex Voice.app"
```

See [Native macOS App](./docs/native-macos-app.md).

## Usage

1. Put focus on the Codex conversation you want to use.
2. Open Codex Voice.
3. Click the microphone.
4. Speak naturally.
5. Review or edit the transcript.
6. Click **Insert into Codex**.
7. Send manually, or enable **Auto-send** if you want Codex Voice to press Return after insertion.

## Permissions

Automatic insertion requires macOS Accessibility permission for the app that launched Codex Voice Helper.

If permission is missing, Codex Voice will copy the transcript to the clipboard instead.

See [macOS Accessibility Permission](./docs/accessibility-macos.md).

## Language

Codex Voice currently supports Chinese and English UI/speech targets.

It reads the browser/system language automatically:

- Chinese locales use `zh-CN`.
- Other locales use `en-US`.

## File Structure

```text
codex-voice/
  .codex-plugin/
    plugin.json
  assets/
    mic-bar.html
    icons/
      mic.svg
  docs/
    ui-states.md
  scripts/
    bridge.js
    insert-into-codex-macos.applescript
    open-codex-voice
  skills/
    codex-voice/
      SKILL.md
```

## Development Notes

The mic window calls Codex Voice Helper at `127.0.0.1:47732`.

Important endpoints:

- `GET /health`
- `POST /insert`
- `POST /clipboard`

`POST /insert` accepts:

```json
{
  "text": "Prompt text",
  "autoSend": false
}
```

Response:

```json
{
  "ok": true,
  "mode": "accessibility"
}
```

If automatic insertion fails, Codex Voice Helper copies to the clipboard and returns:

```json
{
  "ok": true,
  "mode": "clipboard",
  "message": "Automatic insertion failed; copied to clipboard instead."
}
```

## Safety

Codex can edit files and run commands. Auto-send is therefore available but off by default.

The safer default flow is:

```text
Speak -> transcribe -> review -> insert into composer -> user sends
```

## Roadmap

- Route A: native lightweight SwiftUI macOS app with Apple Speech Recognition.
- Improve Codex composer detection.
- Add press-and-hold recording.
- Add a true floating overlay once the MVP is validated.
- Add optional Whisper or Realtime API recognition for users who want better multilingual quality.
- Add a richer prompt-refinement workflow.
