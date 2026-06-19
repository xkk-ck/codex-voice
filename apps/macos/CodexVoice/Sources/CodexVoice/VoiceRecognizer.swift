import AVFoundation
import Foundation
import Speech

enum VoicePermissionResult {
    case allowed
    case speechDenied
    case microphoneDenied
}

enum VoicePermissionFlow {
    static func request(_ completion: @escaping @Sendable (VoicePermissionResult) -> Void) {
        requestSpeech { speechAllowed in
            guard speechAllowed else {
                completion(.speechDenied)
                return
            }

            requestMicrophone { micAllowed in
                completion(micAllowed ? .allowed : .microphoneDenied)
            }
        }
    }

    private static func requestSpeech(_ completion: @escaping @Sendable (Bool) -> Void) {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { status in
                completion(status == .authorized)
            }
        @unknown default:
            completion(false)
        }
    }

    private static func requestMicrophone(_ completion: @escaping @Sendable (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { allowed in
                completion(allowed)
            }
        @unknown default:
            completion(false)
        }
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

@MainActor
final class VoiceRecognizer: ObservableObject {
    @Published var isListening = false
    @Published var transcript = ""
    @Published var status = Copy().readyStatus

    private let copy = Copy()
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?

    func toggle() {
        if isListening {
            stop()
        } else {
            start()
        }
    }

    func start() {
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
                case .speechDenied:
                    self.status = self.copy.speechDeniedStatus
                case .microphoneDenied:
                    self.status = self.copy.microphoneDeniedStatus
                }
            }
        }
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        isListening = false
        if status == copy.listeningStatus || status == copy.startingStatus {
            status = copy.readyStatus
        }
    }

    private func startAfterPermissions() {
        do {
            try beginRecognition()
        } catch {
            status = error.localizedDescription
            stop()
        }
    }

    private func beginRecognition() throws {
        stop()

        let locale = Locale(identifier: AppLanguage.current.speechLocaleIdentifier)
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            status = copy.speechUnavailableStatus
            return
        }

        self.recognizer = recognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        SpeechRuntime.installTap(on: inputNode, format: recordingFormat, request: request)

        audioEngine.prepare()
        try audioEngine.start()

        isListening = true
        status = copy.listeningStatus

        task = SpeechRuntime.startRecognition(recognizer: recognizer, request: request) { [weak self] update in
            Task { @MainActor in
                guard let self else { return }
                if let transcript = update.transcript {
                    self.transcript = transcript
                    if update.isFinal {
                        self.stop()
                    }
                }
                if let errorDescription = update.errorDescription {
                    self.status = errorDescription
                    self.stop()
                }
            }
        }
    }
}
