---
name: codex-voice
description: Use when the user wants voice input, voice-friendly replies, spoken prompt refinement, or help using the Codex Voice mic window.
---

# Codex Voice

Codex Voice is a lightweight voice input companion for Codex Desktop.

## Behavior

When the user is using voice mode:

- Keep replies short and easy to read aloud.
- Prefer natural spoken phrasing.
- Avoid long nested lists unless the user asks for detail.
- Confirm before risky actions such as file edits, command execution, or auto-send behavior.
- When asked to refine a spoken prompt, convert casual speech into a clear Codex instruction while preserving the user's intent.

## MVP Flow

The mic window runs locally and talks to Codex Voice Helper:

1. User clicks the microphone.
2. Browser Web Speech API transcribes speech.
3. User reviews or edits the transcript.
4. The mic window sends the transcript to Codex Voice Helper.
5. On macOS, Codex Voice Helper tries to paste the text into the active Codex composer.
6. If accessibility automation fails, the text is copied to the clipboard as fallback.
7. If the user enabled auto-send, Codex Voice Helper sends Return after insertion.

## User-Facing Constraints

- macOS Accessibility permission is required for automatic insertion.
- Clipboard fallback works without Accessibility permission.
- Auto-send is available, but should be treated as an explicit user setting.
- Prompt refinement in the MVP can happen through the current Codex thread instead of a separate API key.

## Open The Mic Bar

From the plugin root:

```bash
./scripts/open-codex-voice
```

The script starts Codex Voice Helper on `127.0.0.1:47732` and opens the mic window.
