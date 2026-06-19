import Foundation

enum AppLanguage {
    case chinese
    case english

    static var current: AppLanguage {
        let code = Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
        return code.hasPrefix("zh") ? .chinese : .english
    }

    var speechLocaleIdentifier: String {
        switch self {
        case .chinese:
            return "zh-CN"
        case .english:
            return "en-US"
        }
    }
}

struct Copy {
    let language = AppLanguage.current

    var idleTitle: String { language == .chinese ? "点击说话" : "Tap to speak" }
    var listeningTitle: String { language == .chinese ? "正在听" : "Listening" }
    var stopTitle: String { language == .chinese ? "停止" : "Stop" }
    var insertTitle: String { language == .chinese ? "填入 Codex" : "Insert into Codex" }
    var copyTitle: String { language == .chinese ? "复制" : "Copy" }
    var autoSendTitle: String { language == .chinese ? "自动发送" : "Auto-send" }
    var placeholder: String { language == .chinese ? "说点什么，或直接在这里编辑..." : "Speak, or edit the transcript here..." }
    var permissionTitle: String { language == .chinese ? "开启权限" : "Enable permissions" }
    var readyStatus: String { language == .chinese ? "就绪" : "Ready" }
    var requestingPermissionStatus: String { language == .chinese ? "正在请求语音权限..." : "Requesting speech permissions..." }
    var startingStatus: String { language == .chinese ? "正在启动麦克风..." : "Starting microphone..." }
    var listeningStatus: String { language == .chinese ? "正在转写..." : "Transcribing..." }
    var copiedStatus: String { language == .chinese ? "已复制到剪贴板" : "Copied to clipboard" }
    var insertedStatus: String { language == .chinese ? "已填入 Codex" : "Inserted into Codex" }
    var noTextStatus: String { language == .chinese ? "先说一句或输入文本" : "Speak or type something first" }
    var accessibilityMissingStatus: String {
        language == .chinese
            ? "需要给 Codex Voice 辅助功能权限；已先复制到剪贴板"
            : "Accessibility permission is needed; copied to clipboard"
    }
    var speechUnavailableStatus: String {
        language == .chinese
            ? "当前系统语音识别不可用"
            : "Speech recognition is unavailable"
    }
    var micDeniedStatus: String {
        language == .chinese
            ? "需要麦克风和语音识别权限"
            : "Microphone and speech recognition permissions are needed"
    }
    var speechDeniedStatus: String {
        language == .chinese
            ? "需要开启语音识别权限"
            : "Speech Recognition permission is needed"
    }
    var microphoneDeniedStatus: String {
        language == .chinese
            ? "需要开启麦克风权限"
            : "Microphone permission is needed"
    }
    var permissionTimeoutStatus: String {
        language == .chinese
            ? "权限请求超时，请到系统设置开启麦克风和语音识别"
            : "Permission request timed out. Enable Microphone and Speech Recognition in System Settings."
    }
}
