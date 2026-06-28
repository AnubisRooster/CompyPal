import Foundation

/// Stub engine for whisper.cpp local transcription.
/// Replace `transcribe(audioData:)` with a real whisper.cpp binding when available.
/// See: https://github.com/ggerganov/whisper.cpp
@MainActor
final class WhisperSTTEngine: STTEngine {
    let isAvailable: Bool = false // returns false until whisper model is bundled

    func transcribe(audioData: Data) async throws -> String {
        throw STTError.unavailable
    }

    func cancel() {}
}
