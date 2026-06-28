import Foundation
import AVFoundation

@MainActor
class TTSEngine: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var rangeCallback: ((NSRange) -> Void)?
    private var completion: (() -> Void)?

    @Published private(set) var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, voiceId: String = "com.apple.voice.compact.en-US.Samantha", pitch: Double = 1.0, rate: Double = 0.5, rangeCallback: ((NSRange) -> Void)? = nil, completion: (() -> Void)? = nil) {
        stop()
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        self.rangeCallback = rangeCallback
        self.completion = completion

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
        completion = nil
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

extension TTSEngine: @preconcurrency AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        rangeCallback?(characterRange)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        completion?()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
