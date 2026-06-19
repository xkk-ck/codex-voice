# Codex Voice Plugin

[English](./README.md)

Codex Voice 是一个面向 Codex Desktop 的轻量语音输入伴随插件。

它提供一个小型话筒窗口，让你可以自然说话、确认转写内容，并把文本填入 Codex 输入框。在 macOS 上，它可以通过辅助功能自动化把内容粘贴到 Codex；如果没有权限，则自动回退为复制到剪贴板。

## MVP 决策

- UI：小型 Chrome app 风格话筒窗口，而不是普通浏览器标签页或笨重桌面应用。
- 语音识别：浏览器 Web Speech API，并根据浏览器/系统语言自动选择中文或英文。
- 输入方式：优先 macOS 辅助功能自动化，其次剪贴板回退。
- 自动发送：进入 MVP，但默认关闭。
- Prompt 润色：优先使用当前 Codex 线程，避免要求额外 API Key。

## 快速开始

```bash
./scripts/install-macos-helper-app
./scripts/open-codex-voice
```

这个命令会启动 Codex Voice 辅助组件，并打开话筒窗口。

为了让 macOS 权限目标更清楚，建议先运行一次 `install-macos-helper-app`，之后从 `~/Applications` 启动 `Codex Voice Helper.app`。

完整 MVP 使用说明见：[MVP 使用说明](./docs/mvp-usage.zh-CN.md)。

## 使用方式

1. 聚焦你想使用的 Codex 对话。
2. 打开 Codex Voice。
3. 点击话筒。
4. 自然说话。
5. 检查或编辑转写内容。
6. 点击 **Insert into Codex**。
7. 手动发送；如果希望 Codex Voice 填入后自动按 Return，可以开启 **Auto-send**。

## 权限

自动填入需要给启动 Codex Voice 辅助组件的应用授予 macOS 辅助功能权限。

如果缺少权限，Codex Voice 会把转写内容复制到剪贴板。

查看 [macOS 辅助功能权限说明](./docs/accessibility-macos.zh-CN.md)。

## 语言

Codex Voice 目前支持中文和英文 UI/语音目标。

它会自动读取浏览器/系统语言：

- 中文环境使用 `zh-CN`。
- 其他环境使用 `en-US`。

## 文件结构

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
    ui-states.zh-CN.md
  scripts/
    bridge.js
    insert-into-codex-macos.applescript
    open-codex-voice
  skills/
    codex-voice/
      SKILL.md
```

## 开发说明

话筒窗口会调用 Codex Voice 辅助组件：`127.0.0.1:47732`。

重要接口：

- `GET /health`
- `POST /insert`
- `POST /clipboard`

`POST /insert` 请求：

```json
{
  "text": "Prompt text",
  "autoSend": false
}
```

响应：

```json
{
  "ok": true,
  "mode": "accessibility"
}
```

如果自动填入失败，Codex Voice 辅助组件会复制到剪贴板，并返回：

```json
{
  "ok": true,
  "mode": "clipboard",
  "message": "Automatic insertion failed; copied to clipboard instead."
}
```

## 安全

Codex 可以修改文件和运行命令。因此 Auto-send 可用，但默认关闭。

更安全的默认流程是：

```text
说话 -> 转写 -> 检查 -> 填入输入框 -> 用户发送
```

## 路线图

- 路线 A：使用 Apple Speech Recognition 的 SwiftUI 原生 macOS 轻量 App。
- 改进 Codex 输入框检测。
- 添加按住说话。
- 在 MVP 验证后，增加真正的悬浮覆盖层。
- 为需要更好多语言识别效果的用户增加可选 Whisper 或 Realtime API 模式。
- 增加更完整的 prompt 润色流程。
