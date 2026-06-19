import AppKit
import ApplicationServices

enum CodexInserter {
    static func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    static func requestAccessibilityPermission() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func insertIntoCodex(_ text: String, autoSend: Bool) -> Bool {
        copyToClipboard(text)

        guard requestAccessibilityPermission() else {
            return false
        }

        activateCodex()
        Thread.sleep(forTimeInterval: 0.25)
        sendKey(keyCode: 9, flags: .maskCommand)

        if autoSend {
            Thread.sleep(forTimeInterval: 0.1)
            sendKey(keyCode: 36, flags: [])
        }

        return true
    }

    private static func activateCodex() {
        let apps = NSWorkspace.shared.runningApplications
        let candidates = apps.filter { app in
            let name = app.localizedName?.lowercased() ?? ""
            let bundle = app.bundleIdentifier?.lowercased() ?? ""
            return name == "codex" || name.contains("codex") || bundle.contains("codex")
        }

        candidates.first?.activate(options: [.activateAllWindows])
    }

    private static func sendKey(keyCode: CGKeyCode, flags: CGEventFlags) {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        down?.flags = flags
        up?.flags = flags
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
