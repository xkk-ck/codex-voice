# Native macOS App

[简体中文](./native-macos-app.zh-CN.md)

Route A upgrades Codex Voice from a browser mic window to a lightweight native macOS app.

The native app is currently prepared for review on the `route-a-swiftui-native-app` branch.

## Goals

- Use macOS native speech recognition through Apple Speech.
- Avoid a separate browser permission prompt.
- Show a clear permission target: `Codex Voice.app`.
- Keep the app lightweight and open-source friendly.
- Avoid OpenAI API cost in the MVP.
- Keep optional OpenAI transcription as future work, with user-provided API keys.

## Current Features

- Floating compact mic bar.
- System language detection for Chinese or English.
- Apple Speech Recognition through `SFSpeechRecognizer`.
- Microphone capture through `AVAudioEngine`.
- Transcript review and editing.
- Copy to clipboard.
- Insert into Codex with macOS Accessibility automation.
- Optional Auto-send.
- Clipboard fallback if Accessibility permission is unavailable.

## Build

Requirements:

- macOS 14 or newer.
- Xcode Command Line Tools.
- Swift 6 toolchain.

From the repository root:

```bash
./scripts/build-macos-app
```

The app is created at:

```text
apps/macos/CodexVoice/dist/Codex Voice.app
```

## Run

```bash
open "apps/macos/CodexVoice/dist/Codex Voice.app"
```

## Permissions

The native app may request:

- Microphone permission.
- Speech Recognition permission.
- Accessibility permission.

Microphone and Speech Recognition are needed for transcription.

Accessibility is needed only for direct insertion into Codex. If Accessibility is denied, Codex Voice still copies the transcript to the clipboard.

To enable direct insertion:

1. Open System Settings.
2. Go to Privacy & Security.
3. Open Accessibility.
4. Enable `Codex Voice.app`.
5. Restart Codex Voice.

## Safety

Auto-send is off by default.

The safer flow is:

```text
Speak -> review transcript -> insert -> send manually
```

## Self-Test Status

Completed locally:

- Swift release build passes.
- `.app` bundle is generated.
- `Info.plist` validates with `plutil`.
- Ad-hoc code signature verifies with `codesign`.
- App launches as a floating accessory window.

Pending user acceptance:

- Microphone permission flow.
- Speech Recognition permission flow.
- Accessibility insertion into the user's Codex Desktop session.
- Auto-send behavior in a real Codex conversation.

## Future Work

- Package a downloadable release asset.
- Add notarization instructions.
- Add a menu bar icon.
- Add press-and-hold recording.
- Add optional OpenAI transcription using a user-provided API key.
