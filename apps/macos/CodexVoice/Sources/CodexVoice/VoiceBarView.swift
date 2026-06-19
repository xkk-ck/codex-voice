import SwiftUI

struct VoiceBarView: View {
    @StateObject private var recognizer = VoiceRecognizer()
    @State private var autoSend = false
    @State private var status = Copy().readyStatus
    @State private var didRunSelfTest = false

    private let copy = Copy()

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: recognizer.toggle) {
                    ZStack {
                        Circle()
                            .fill(recognizer.isListening ? Color.red : Color.accentColor)
                            .frame(width: 46, height: 46)
                        Image(systemName: recognizer.isListening ? "stop.fill" : "mic.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .help(recognizer.isListening ? copy.stopTitle : copy.idleTitle)

                VStack(alignment: .leading, spacing: 3) {
                    Text(recognizer.isListening ? copy.listeningTitle : "Codex Voice")
                        .font(.system(size: 15, weight: .semibold))
                    Text(currentStatus)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Toggle(copy.autoSendTitle, isOn: $autoSend)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .font(.system(size: 12))

                Button {
                    recognizer.stop()
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Quit Codex Voice")
            }

            TextEditor(text: $recognizer.transcript)
                .font(.system(size: 14))
                .scrollContentBackground(.hidden)
                .frame(height: 52)
                .padding(6)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(alignment: .topLeading) {
                    if recognizer.transcript.isEmpty {
                        Text(copy.placeholder)
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }
                }

            HStack(spacing: 8) {
                Button(copy.speechPermissionTitle) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .controlSize(.small)

                Button(copy.accessibilityPermissionTitle) {
                    _ = CodexInserter.requestAccessibilityPermission()
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .controlSize(.small)

                Spacer()

                Button(copy.copyTitle) {
                    let text = recognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else {
                        status = copy.noTextStatus
                        return
                    }
                    CodexInserter.copyToClipboard(text)
                    status = copy.copiedStatus
                }
                .controlSize(.small)

                Button(copy.insertTitle) {
                    let text = recognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else {
                        status = copy.noTextStatus
                        return
                    }
                    let inserted = CodexInserter.insertIntoCodex(text, autoSend: autoSend)
                    status = inserted ? copy.insertedStatus : copy.accessibilityMissingStatus
                }
                .keyboardShortcut(.return, modifiers: .command)
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .frame(width: 420)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08))
        }
        .onAppear(perform: runSelfTestIfRequested)
    }

    private var currentStatus: String {
        if recognizer.status != copy.readyStatus {
            return recognizer.status
        }
        return status
    }

    private func runSelfTestIfRequested() {
        guard !didRunSelfTest else { return }
        guard let index = CommandLine.arguments.firstIndex(of: "--self-test-record") else { return }
        didRunSelfTest = true

        let seconds: UInt64
        if CommandLine.arguments.indices.contains(index + 1),
           let parsed = UInt64(CommandLine.arguments[index + 1]) {
            seconds = parsed
        } else {
            seconds = 15
        }

        recognizer.start()
        Task {
            try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            await MainActor.run {
                recognizer.stop()
                NSApp.terminate(nil)
            }
        }
    }
}
