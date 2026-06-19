# macOS Accessibility Permission

[简体中文](./accessibility-macos.zh-CN.md)

Codex Voice can paste transcripts into Codex Desktop automatically on macOS.

This requires Accessibility permission for the app that launched Codex Voice Helper. The browser window itself is not what needs this permission; the local helper process performs the paste action.

macOS often does not show an Accessibility permission prompt automatically. If insertion fails, Codex Voice shows an "Open Accessibility Settings" button and copies the transcript to the clipboard first.

## Enable Permission

1. Open System Settings.
2. Go to Privacy & Security.
3. Open Accessibility.
4. Enable the app that launched Codex Voice Helper.
5. Restart Codex Voice.

If you are not sure which app to enable, it is usually one of:

- Codex Voice Helper, if you installed the helper app
- Codex Voice Helper Runtime, if macOS shows the actual runtime
- Terminal
- iTerm
- Codex
- The app that launched `scripts/open-codex-voice`

If you already see `node`, you can temporarily enable `node` for testing. The helper app now tries to show the runtime as `Codex Voice Helper Runtime` instead.

## Fallback

If Accessibility permission is not available, Codex Voice copies the transcript to the clipboard instead.
