# MVP 使用说明

[English](./mvp-usage.md)

这份文档说明当前的浏览器版 MVP。

## 它能做什么

Codex Voice MVP 会打开一个小型话筒窗口。你可以说话、检查转写内容，然后把文本填入 Codex Desktop。

当前 MVP 使用：

- 浏览器 Web Speech API 做语音识别。
- 本地 Node.js 辅助进程做粘贴自动化。
- macOS 辅助功能权限做直接填入。
- 如果没有辅助功能权限，则回退为复制到剪贴板。

## 运行要求

- macOS。
- Codex Desktop。
- 推荐 Google Chrome，因为 Web Speech API 支持更好。
- Node.js 18 或更高版本。

## 安装

在仓库根目录运行：

```bash
./scripts/install-macos-helper-app
```

这个命令会创建：

```text
~/Applications/Codex Voice Helper.app
```

Helper app 可以让 macOS 权限目标更清晰，不必让普通用户理解 `node` 进程是什么。

## 启动

```bash
./scripts/open-codex-voice
```

这个命令会启动本地辅助进程 `127.0.0.1:47732`，并打开话筒窗口。

## 基本流程

1. 打开你想使用的 Codex 对话。
2. 启动 Codex Voice。
3. 点击话筒按钮。
4. 自然说话。
5. 检查或编辑转写内容。
6. 点击 **Insert into Codex**。
7. 手动发送；或者在填入前开启 **Auto-send**。

## 权限

Chrome 可能会请求麦克风权限。要使用浏览器语音识别，需要允许。

macOS 很多时候不会自动弹出辅助功能授权提示。如果直接填入失败：

1. 打开系统设置。
2. 进入隐私与安全性。
3. 打开辅助功能。
4. 如果看到 `Codex Voice Helper.app`，启用它。
5. 重启 Codex Voice。

如果列表里没有 helper，可以在填入失败后点击话筒窗口里的 **Open Accessibility Settings**，再手动添加或启用 helper app。

## 回退行为

如果直接填入失败，Codex Voice 会把转写内容复制到剪贴板。

这时你可以手动在 Codex 里按 `Command-V` 粘贴。

## 自动发送

Auto-send 会在填入后按 Return。它默认关闭。

建议只在你确认转写效果稳定后再开启，因为 Codex 可以编辑文件和运行命令。

## 语言

UI 和语音目标会跟随浏览器/系统语言：

- 中文环境使用 `zh-CN`。
- 其他环境使用 `en-US`。

## 常见问题

如果话筒无法启动，请使用 Chrome，并允许麦克风权限。

如果无法自动填入，请给 helper app 开启 macOS 辅助功能权限。

如果辅助进程无法启动，请确认已安装 Node.js：

```bash
node --version
```

如果 `47732` 端口被占用，可以关闭旧进程，或换一个端口：

```bash
CODEX_VOICE_PORT=47733 ./scripts/open-codex-voice
```
