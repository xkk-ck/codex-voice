import AppKit
import AVFoundation
import Foundation
import Speech

enum VoicePermissionResult {
    case allowed
    case speechNotDetermined
    case speechDenied(String)
    case speechTimeout
    case microphoneDenied
}

enum VoicePermissionFlow {
    static func request(_ completion: @escaping @Sendable (VoicePermissionResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            requestSpeechWithTimeout { result in
                switch result {
                case .allowed:
                    requestMicrophone { micAllowed in
                        completion(micAllowed ? .allowed : .microphoneDenied)
                    }
                case .speechNotDetermined, .speechDenied, .speechTimeout, .microphoneDenied:
                    completion(result)
                }
            }
        }
    }

    static func requestSpeechWithTimeout(_ completion: @escaping @Sendable (VoicePermissionResult) -> Void) {
        let once = Once()

        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            once.run { completion(.allowed) }
        case .denied, .restricted:
            once.run { completion(.speechDenied("initial status: \(SFSpeechRecognizer.authorizationStatus())")) }
        case .notDetermined:
            once.run { completion(.speechNotDetermined) }
        @unknown default:
            once.run { completion(.speechDenied("unknown status: \(SFSpeechRecognizer.authorizationStatus())")) }
        }
    }

    private static func requestMicrophone(_ completion: @escaping @Sendable (Bool) -> Void) {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioApplication.requestRecordPermission { allowed in
                completion(allowed)
            }
        @unknown default:
            completion(false)
        }
    }
}

final class Once: @unchecked Sendable {
    private let lock = NSLock()
    private var didRun = false

    func run(_ body: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        guard !didRun else { return }
        didRun = true
        body()
    }
}

struct SpeechUpdate: Sendable {
    let transcript: String?
    let isFinal: Bool
    let errorDescription: String?
}

enum SpeechRuntime {
    static func installTap(
        on inputNode: AVAudioInputNode,
        format: AVAudioFormat,
        request: SFSpeechAudioBufferRecognitionRequest
    ) {
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
    }

    static func startRecognition(
        recognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest,
        onUpdate: @escaping @Sendable (SpeechUpdate) -> Void
    ) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { result, error in
            onUpdate(
                SpeechUpdate(
                    transcript: result?.bestTranscription.formattedString,
                    isFinal: result?.isFinal ?? false,
                    errorDescription: error?.localizedDescription
                )
            )
        }
    }
}

enum SelfTestReporter {
    static func write(_ value: String) {
        guard let path = ProcessInfo.processInfo.environment["CODEX_VOICE_SELF_TEST_STATUS"] else { return }
        try? value.write(toFile: path, atomically: true, encoding: .utf8)
    }
}

@MainActor
final class VoiceRecognizer: ObservableObject {
    @Published var isListening = false {
        didSet {
            if isListening {
                SelfTestReporter.write("listening")
            }
        }
    }
    @Published var transcript = ""
    @Published var status = Copy().readyStatus {
        didSet {
            SelfTestReporter.write(status)
        }
    }

    private let copy = Copy()
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private var shouldKeepListening = false
    private var segmentBase = ""

    func toggle() {
        if isListening {
            stop()
        } else {
            start()
        }
    }

    func start() {
        shouldKeepListening = true
        status = copy.requestingPermissionStatus

        let timeout = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 12_000_000_000)
            await MainActor.run {
                guard let self, !self.isListening, self.status == self.copy.requestingPermissionStatus else { return }
                self.status = self.copy.permissionTimeoutStatus
            }
        }

        VoicePermissionFlow.request { [weak self] result in
            Task { @MainActor in
                timeout.cancel()
                guard let self else { return }

                switch result {
                case .allowed:
                    self.status = self.copy.startingStatus
                    self.startAfterPermissions()
                case .speechNotDetermined:
                    self.shouldKeepListening = false
                    self.status = self.copy.speechNotDeterminedStatus
                    self.openSpeechSettings()
                case .speechDenied(let detail):
                    self.shouldKeepListening = false
                    self.status = "\(self.copy.speechDeniedStatus): \(detail)"
                case .speechTimeout:
                    self.shouldKeepListening = false
                    self.status = self.copy.speechTimeoutStatus
                case .microphoneDenied:
                    self.shouldKeepListening = false
                    self.status = self.copy.microphoneDeniedStatus
                }
            }
        }
    }

    func stop() {
        shouldKeepListening = false
        stopCurrentRecognition()
        if status == copy.listeningStatus || status == copy.startingStatus {
            status = copy.readyStatus
        }
    }

    private func stopCurrentRecognition() {
        task?.cancel()
        request?.endAudio()

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        task = nil
        request = nil
        isListening = false
    }

    private func startAfterPermissions() {
        do {
            try beginRecognition()
        } catch {
            shouldKeepListening = false
            status = error.localizedDescription
            stopCurrentRecognition()
        }
    }

    private func beginRecognition() throws {
        resetRecognitionSession()

        let locale = Locale(identifier: AppLanguage.current.speechLocaleIdentifier)
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            status = copy.speechUnavailableStatus
            shouldKeepListening = false
            return
        }

        self.recognizer = recognizer
        segmentBase = transcript.trimmingCharacters(in: .whitespacesAndNewlines)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.channelCount > 0, recordingFormat.sampleRate > 0 else {
            status = copy.microphoneUnavailableStatus
            shouldKeepListening = false
            return
        }
        SpeechRuntime.installTap(on: inputNode, format: recordingFormat, request: request)

        audioEngine.prepare()
        try audioEngine.start()

        isListening = true
        status = copy.listeningStatus

        task = SpeechRuntime.startRecognition(recognizer: recognizer, request: request) { [weak self] update in
            Task { @MainActor in
                guard let self else { return }
                if let transcript = update.transcript {
                    self.transcript = self.combinedTranscript(with: transcript)
                    if update.isFinal {
                        self.restartRecognitionIfNeeded()
                    }
                }
                if let errorDescription = update.errorDescription {
                    self.handleRecognitionError(errorDescription)
                }
            }
        }
    }

    private func resetRecognitionSession() {
        task?.cancel()
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        task = nil
        request = nil
        isListening = false
    }

    private func restartRecognitionIfNeeded() {
        guard shouldKeepListening else { return }
        do {
            try beginRecognition()
        } catch {
            status = error.localizedDescription
            stopCurrentRecognition()
            shouldKeepListening = false
        }
    }

    private func handleRecognitionError(_ errorDescription: String) {
        guard shouldKeepListening else { return }

        let lowercased = errorDescription.lowercased()
        if lowercased.contains("cancel") {
            return
        }

        status = errorDescription
        stopCurrentRecognition()
        shouldKeepListening = false
    }

    private func combinedTranscript(with segment: String) -> String {
        let cleanSegment = segment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !segmentBase.isEmpty else { return cleanSegment }
        guard !cleanSegment.isEmpty else { return segmentBase }
        return "\(segmentBase)\n\(cleanSegment)"
    }

    private func openSpeechSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition") else { return }
        NSWorkspace.shared.open(url)
    }
}
