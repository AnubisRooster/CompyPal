import Foundation
import Speech

@MainActor
final class AppleSpeechSTTEngine: NSObject, STTEngine {
    let isAvailable: Bool = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))?.supportsOnDeviceRecognition ?? false
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionTask: SFSpeechRecognitionTask?

    func transcribe(audioData: Data) async throws -> String {
        cancel()
        let request = SFSpeechURLRecognitionRequest(url: writeTmpFile(data: audioData))
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = true
        return try await withCheckedThrowingContinuation { [weak self] cont in
            guard let self, let speechRecognizer else {
                cont.resume(throwing: STTError.unavailable)
                return
            }
            recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
                if let result {
                    cont.resume(returning: result.bestTranscription.formattedString)
                } else if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(throwing: STTError.noResult)
                }
                self.recognitionTask = nil
            }
        }
    }

    func cancel() {
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    private func writeTmpFile(data: Data) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("stt_\(UUID().uuidString).wav")
        try? data.write(to: url)
        return url
    }
}

enum STTError: Error {
    case unavailable
    case noResult
}
