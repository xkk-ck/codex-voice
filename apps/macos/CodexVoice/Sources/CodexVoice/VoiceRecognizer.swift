import AVFoundation
import Foundation
import Speech

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
        requestPermissions { [weak self] allowed in
            Task { @MainActor in
                guard let self else { return }
                guard allowed else {
                    self.status = self.copy.micDeniedStatus
                    return
                }
                self.startAfterPermissions()
            }
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

    nonisolated private func requestPermissions(_ completion: @escaping @Sendable (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            guard speechStatus == .authorized else {
                completion(false)
                return
            }

            Task {
                let micAllowed = await AVAudioApplication.requestRecordPermission()
                completion(micAllowed)
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
        if status == copy.listeningStatus {
            status = copy.readyStatus
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
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isListening = true
        status = copy.listeningStatus

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.stop()
                    }
                }
                if let error {
                    self.status = error.localizedDescription
                    self.stop()
                }
            }
        }
    }
}
