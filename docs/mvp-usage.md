# MVP Usage Guide

[简体中文](./mvp-usage.zh-CN.md)

This guide covers the current browser-based MVP.

## What It Does

Codex Voice MVP opens a compact microphone window. You can speak, review the transcript, and insert the text into Codex Desktop.

The MVP uses:

- Browser Web Speech API for speech recognition.
- A local Node.js helper for paste automation.
- macOS Accessibility permission for direct insertion.
- Clipboard fallback when Accessibility permission is not available.

## Requirements

- macOS.
- Codex Desktop.
- Google Chrome, recommended for Web Speech API support.
- Node.js 18 or newer.

## Install

From the repository root:

```bash
./scripts/install-macos-helper-app
```

This creates:

```text
~/Applications/Codex Voice Helper.app
```

The helper app gives macOS a clearer permission target than a raw `node` process.

## Start

```bash
./scripts/open-codex-voice
```

This starts the local helper at `127.0.0.1:47732` and opens the mic window.

## Basic Flow

1. Open the Codex conversation you want to use.
2. Start Codex Voice.
3. Click the microphone button.
4. Speak naturally.
5. Review or edit the transcript.
6. Click **Insert into Codex**.
7. Send manually, or turn on **Auto-send** before insertion.

## Permissions

Chrome may ask for microphone access. Allow it if you want browser speech recognition.

macOS may not automatically show an Accessibility prompt. If direct insertion fails:

1. Open System Settings.
2. Go to Privacy & Security.
3. Open Accessibility.
4. Enable `Codex Voice Helper.app` if it appears.
5. Restart Codex Voice.

If the helper is not listed, click **Open Accessibility Settings** in the mic window after a failed insertion, then add or enable the helper app manually.

## Fallback Behavior

If direct insertion fails, Codex Voice copies the transcript to the clipboard.

You can then paste into Codex manually with `Command-V`.

## Auto-send

Auto-send presses Return after insertion. It is off by default.

Use it only after you trust the transcript, because Codex can edit files and run commands.

## Language

The UI and speech language follow the browser/system language:

- Chinese locales use `zh-CN`.
- Other locales use `en-US`.

## Troubleshooting

If the microphone does not start, use Chrome and allow microphone permission.

If insertion does not work, enable macOS Accessibility permission for the helper app.

If the helper does not start, make sure Node.js is installed and available in your shell:

```bash
node --version
```

If port `47732` is already in use, stop the old helper process or set another port:

```bash
CODEX_VOICE_PORT=47733 ./scripts/open-codex-voice
```
