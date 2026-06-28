import Foundation

protocol STTEngine: AnyObject {
    var isAvailable: Bool { get }
    func transcribe(audioData: Data) async throws -> String
    func cancel()
}

enum STTEngineType {
    case appleSpeech
    case whisper

    @MainActor
    func make() -> STTEngine {
        switch self {
        case .appleSpeech:
            return AppleSpeechSTTEngine()
        case .whisper:
            return WhisperSTTEngine()
        }
    }
}
