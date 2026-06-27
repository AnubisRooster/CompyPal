import Foundation
import AVFoundation

@MainActor
class TTSEngine: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var onMouthOpen: ((Float) -> Void)?

    @Published private(set) var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, voiceId: String = "com.apple.voice.compact.en-US.Samantha", pitch: Double = 1.0, rate: Double = 0.5, onMouthOpen: ((Float) -> Void)? = nil) {
        stop()
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        self.onMouthOpen = onMouthOpen

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId) ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.pitchMultiplier = Float(pitch)
        utterance.rate = Float(rate)
        utterance.volume = 1.0

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        onMouthOpen?(0)
        onMouthOpen = nil
    }

    var isPaused: Bool {
        synthesizer.isPaused
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }

    func resume() {
        synthesizer.continueSpeaking()
    }
}

extension TTSEngine: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        onMouthOpen?(0)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        onMouthOpen?(0)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let totalLen = utterance.speechString.utf16.count
        guard totalLen > 0 else { return }
        let progress = Float(characterRange.location) / Float(totalLen)
        let mouthValue = sinusoidMouth(from: progress)
        onMouthOpen?(mouthValue)
    }

    private func sinusoidMouth(from progress: Float) -> Float {
        let phase = progress * Float.pi * 4
        return abs(sin(phase)) * 0.6 + 0.1
    }
}
