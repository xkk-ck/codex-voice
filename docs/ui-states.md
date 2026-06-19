# Codex Voice UI States

## 1. Idle

The mic window is compact. The microphone button uses a simple line icon. Auto-send is visible as a deliberate option.

## 2. Listening

The microphone button switches to a recording state. The transcript area shows interim speech recognition results.

## 3. Review

The user can edit the transcript and choose:

- Insert into Codex
- Copy
- Clear
- Refine in Codex

## 4. Inserted

Codex Voice Helper attempts macOS Accessibility insertion. If it fails, the transcript is copied to the clipboard.

## 5. Error

Errors are recoverable and should be short:

- Microphone unavailable.
- Speech recognition unavailable.
- Codex Voice Helper unavailable.
- Accessibility insertion failed; copied to clipboard.
