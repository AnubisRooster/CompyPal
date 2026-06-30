import Foundation
import AVFoundation

/// Realistic neural text-to-speech via the ElevenLabs API.
///
/// Synthesizes the reply to an MP3, decodes it to compute amplitude energies for lip-sync,
/// plays it back, and drives performance-beat progress against the playback clock. The
/// network + decode happen off the main actor; playback and callbacks run on the main actor
/// so they integrate with the existing avatar speech pipeline. Apple's `TTSEngine` remains
/// the offline fallback when this is disabled or fails.
@MainActor
final class ElevenLabsTTS: NSObject {
    struct Voice: Identifiable, Hashable { let id: String; let name: String }

    enum TTSError: LocalizedError {
        case missingKey
        case http(Int, String)
        case emptyAudio
        case decodeFailed

        var errorDescription: String? {
            switch self {
            case .missingKey: return "No ElevenLabs API key configured."
            case .http(let code, let body): return "ElevenLabs error \(code): \(body)"
            case .emptyAudio: return "ElevenLabs returned no audio."
            case .decodeFailed: return "Could not decode the synthesized audio."
            }
        }
    }

    static let keychainAccount = "elevenlabs_api_key"
    static let defaultVoiceId = "21m00Tcm4TlvDq8ikWAM" // "Rachel" — natural female voice
    static let defaultModelId = "eleven_turbo_v2_5"

    private var player: AVAudioPlayer?
    private var progressTimer: Timer?
    private var currentToken: UInt64 = 0
    private var onProgress: ((NSRange) -> Void)?
    private var completion: (() -> Void)?
    private var spokenText = ""
    private var clipDuration: TimeInterval = 0

    nonisolated static func isValidKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        return trimmed.count > 20 && !trimmed.contains(" ")
    }

    /// Fetches the account's available voices for the Settings picker.
    nonisolated static func fetchVoices(apiKey: String) async throws -> [Voice] {
        var req = URLRequest(url: URL(string: "https://api.elevenlabs.io/v1/voices")!)
        req.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
            throw TTSError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        struct VoicesResponse: Decodable { let voices: [V]; struct V: Decodable { let voice_id: String; let name: String } }
        let decoded = try JSONDecoder().decode(VoicesResponse.self, from: data)
        return decoded.voices.map { Voice(id: $0.voice_id, name: $0.name) }
    }

    /// Synthesizes and speaks `text`. Calls `onStart` (with the decoded energies + duration)
    /// the moment playback begins, `onProgress` as the playback clock advances (so performance
    /// beats fire), `completion` when finished, and `onError` if synthesis fails.
    func speak(_ text: String,
               voiceId: String,
               modelId: String,
               apiKey: String,
               rate: Double = 1.0,
               onStart: @escaping ([Float], TimeInterval) -> Void,
               onProgress: @escaping (NSRange) -> Void,
               completion: @escaping () -> Void,
               onError: @escaping (Error) -> Void) {
        stop()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { completion(); return }
        guard ElevenLabsTTS.isValidKey(apiKey) else { onError(TTSError.missingKey); return }

        currentToken &+= 1
        let token = currentToken

        Task.detached(priority: .userInitiated) {
            do {
                let audio = try await Self.synthesize(text: trimmed, voiceId: voiceId, modelId: modelId, apiKey: apiKey)
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("riven_tts_\(token).mp3")
                try audio.write(to: url)
                let (energies, duration) = Self.decodeEnergies(from: url)
                await MainActor.run {
                    guard self.currentToken == token else { return }
                    self.beginPlayback(url: url, text: trimmed, energies: energies, duration: duration, rate: rate,
                                       onStart: onStart, onProgress: onProgress, completion: completion, onError: onError)
                }
            } catch {
                await MainActor.run {
                    guard self.currentToken == token else { return }
                    onError(error)
                }
            }
        }
    }

    func stop() {
        currentToken &+= 1
        progressTimer?.invalidate()
        progressTimer = nil
        player?.stop()
        player = nil
        completion = nil
        onProgress = nil
    }

    // MARK: - Playback (main actor)

    private func beginPlayback(url: URL, text: String, energies: [Float], duration: TimeInterval, rate: Double,
                               onStart: ([Float], TimeInterval) -> Void,
                               onProgress: @escaping (NSRange) -> Void,
                               completion: @escaping () -> Void,
                               onError: (Error) -> Void) {
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.enableRate = true
            p.rate = Float(max(0.5, min(rate, 2.0)))
            p.delegate = self
            guard p.prepareToPlay() else { onError(TTSError.decodeFailed); return }
            player = p
            spokenText = text
            clipDuration = p.duration > 0 ? p.duration : duration
            self.onProgress = onProgress
            self.completion = completion

            onStart(energies, clipDuration)
            p.play()
            startProgressTimer()
        } catch {
            onError(error)
        }
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickProgress() }
        }
        RunLoop.main.add(timer, forMode: .common)
        progressTimer = timer
    }

    private func tickProgress() {
        guard let player, clipDuration > 0 else { return }
        // Drive beat progress by playback fraction so beats keyed to character offsets fire in
        // step with the audio (lip-sync is handled separately from the decoded energies).
        let fraction = min(max(player.currentTime / clipDuration, 0), 1)
        let location = Int(fraction * Double(spokenText.count))
        onProgress?(NSRange(location: location, length: 0))
    }

    // MARK: - Networking & decode (off main)

    private nonisolated static func synthesize(text: String, voiceId: String, modelId: String, apiKey: String) async throws -> Data {
        let voice = voiceId.isEmpty ? defaultVoiceId : voiceId
        var req = URLRequest(url: URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voice)")!)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        let body: [String: Any] = [
            "text": text,
            "model_id": modelId.isEmpty ? defaultModelId : modelId,
            "voice_settings": ["stability": 0.45, "similarity_boost": 0.8, "style": 0.3, "use_speaker_boost": true],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 30

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
            throw TTSError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        guard !data.isEmpty else { throw TTSError.emptyAudio }
        return data
    }

    /// Decodes the MP3 to PCM and computes per-chunk amplitude energies for lip-sync, reusing
    /// the same energy model as the Apple path so the mouth behaves consistently.
    private nonisolated static func decodeEnergies(from url: URL) -> ([Float], TimeInterval) {
        guard let file = try? AVAudioFile(forReading: url) else { return ([], 0) }
        let format = file.processingFormat
        let frames = AVAudioFrameCount(file.length)
        guard frames > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              (try? file.read(into: buffer)) != nil else { return ([], 0) }
        let energies = TTSEngine.computePCMEnergies(buffer)
        let duration = Double(file.length) / format.sampleRate
        return (energies, duration)
    }
}

extension ElevenLabsTTS: @preconcurrency AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer?.invalidate()
        progressTimer = nil
        let done = completion
        completion = nil
        onProgress = nil
        done?()
    }
}
