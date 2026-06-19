# 原生 macOS App

[English](./native-macos-app.md)

路线 A 会把 Codex Voice 从浏览器话筒窗口升级为轻量原生 macOS App。

当前原生 App 已准备在 `route-a-swiftui-native-app` 分支中验收。

## 目标

- 使用 macOS 原生 Apple Speech 做语音识别。
- 避免浏览器麦克风授权弹窗。
- 让权限目标清晰显示为 `Codex Voice.app`。
- 保持轻量，适合开源。
- MVP 不接 OpenAI API，不让开发者承担 API 成本。
- OpenAI 转写作为后续可选能力，由用户自己提供 API Key。

## 当前功能

- 小型悬浮 mic bar。
- 根据系统语言自动使用中文或英文。
- 通过 `SFSpeechRecognizer` 使用 Apple Speech Recognition。
- 通过 `AVAudioEngine` 采集麦克风。
- 支持检查和编辑转写内容。
- 支持复制到剪贴板。
- 支持通过 macOS 辅助功能自动填入 Codex。
- 支持可选 Auto-send。
- 如果没有辅助功能权限，回退为复制到剪贴板。

## 构建

要求：

- macOS 14 或更高版本。
- Xcode Command Line Tools。
- Swift 6 工具链。

在仓库根目录运行：

```bash
./scripts/build-macos-app
```

App 会生成在：

```text
apps/macos/CodexVoice/dist/Codex Voice.app
```

## 运行

```bash
open "apps/macos/CodexVoice/dist/Codex Voice.app"
```

## 权限

原生 App 可能会请求：

- 麦克风权限。
- 语音识别权限。
- 辅助功能权限。

麦克风和语音识别权限用于转写。

辅助功能权限只用于自动填入 Codex。如果用户拒绝辅助功能权限，Codex Voice 仍然会把转写内容复制到剪贴板。

首次使用时，如果点击话筒后提示需要语音识别权限，请点击 App 内的 **语音识别权限** 按钮，或进入：

```text
系统设置 -> 隐私与安全性 -> 语音识别 -> Codex Voice
```

开启后重新点击话筒即可开始录音。**辅助功能权限不影响录音，只影响自动填入 Codex。**

开启自动填入：

1. 打开系统设置。
2. 进入隐私与安全性。
3. 打开辅助功能。
4. 启用 `Codex Voice.app`。
5. 重启 Codex Voice。

## 安全

Auto-send 默认关闭。

更安全的流程是：

```text
说话 -> 检查转写 -> 填入 -> 手动发送
```

## 自测状态

本地已完成：

- Swift release 构建通过。
- `.app` bundle 成功生成。
- `Info.plist` 通过 `plutil` 校验。
- ad-hoc 签名通过 `codesign` 校验。
- App 可以作为普通 macOS 窗口启动并保持浮在前面。
- 未开启语音识别权限时，App 会给出明确提示并打开系统设置，不再卡在“正在请求语音权限”。
- 未授权路径自测通过，且未产生新的 crash report。

运行自测：

```bash
./scripts/test-macos-app 45
```

如果当前机器还没有给 `Codex Voice.app` 开启语音识别权限，可以先运行：

```bash
./scripts/test-macos-app 10 --allow-permission-needed
```

待用户验收：

- 麦克风权限流程。
- 语音识别权限流程。
- 开启语音识别权限后的 45 秒录音自测。
- 在用户 Codex Desktop 会话中的辅助功能自动填入。
- 真实 Codex 对话中的 Auto-send 行为。

## 后续工作

- 打包可下载 release asset。
- 增加 notarization 说明。
- 增加菜单栏图标。
- 增加按住说话。
- 增加可选 OpenAI 转写，由用户提供 API Key。
