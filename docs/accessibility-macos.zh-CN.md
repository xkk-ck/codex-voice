# macOS 辅助功能权限

[English](./accessibility-macos.md)

Codex Voice 可以在 macOS 上自动把转写文本粘贴到 Codex Desktop。

这需要给启动 Codex Voice 辅助组件的应用授予“辅助功能”权限。浏览器页面本身不需要这个权限；真正执行粘贴动作的是本地辅助组件。

macOS 很多时候不会主动弹出辅助功能授权提示。如果自动填入失败，Codex Voice 会显示“打开辅助功能设置”按钮，并先把内容复制到剪贴板。

## 开启权限

1. 打开系统设置。
2. 进入隐私与安全性。
3. 打开辅助功能。
4. 勾选启动 Codex Voice 辅助组件的终端或应用。
5. 重启 Codex Voice。

如果你不确定该勾选哪个应用，通常是以下之一：

- Codex Voice Helper，如果你安装了 helper app
- Codex Voice Helper Runtime，如果系统显示的是实际运行时
- Terminal
- iTerm
- Codex
- 启动 `scripts/open-codex-voice` 的应用

如果你已经看到 `node`，也可以先临时勾选 `node` 完成测试。新版 helper app 会尽量把这个运行时显示成 `Codex Voice Helper Runtime`。

## 回退

如果没有辅助功能权限，Codex Voice 会把转写文本复制到剪贴板。
