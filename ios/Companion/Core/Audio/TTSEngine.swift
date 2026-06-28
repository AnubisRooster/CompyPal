import Foundation
import AVFoundation

@MainActor
class TTSEngine: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var pcmCallback: ((AVAudioPCMBuffer, Int) -> Void)?
    private var speechText: String = ""

    @Published private(set) var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
        audioEngine.attach(playerNode)
        let mainMixer = audioEngine.mainMixerNode
        audioEngine.connect(playerNode, to: mainMixer, format: nil)
    }

    func speak(_ text: String, voiceId: String = "com.apple.voice.compact.en-US.Samantha", pitch: Double = 1.0, rate: Double = 0.5, pcmCallback: ((AVAudioPCMBuffer, Int) -> Void)? = nil) {
        stop()
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        self.pcmCallback = pcmCallback
        speechText = text

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId) ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.pitchMultiplier = Float(pitch)
        utterance.rate = Float(rate)
        utterance.volume = 1.0

        isSpeaking = true

        Task.detached { [weak self] in
            var buffers: [AVAudioPCMBuffer] = []

            self?.synthesizer.write(utterance) { audioBuffer in
                guard let pcm = audioBuffer as? AVAudioPCMBuffer,
                      let pcmCopy = pcm.copy() as? AVAudioPCMBuffer
                else { return }
                buffers.append(pcmCopy)
            }

            Task { @MainActor [weak self] in
                guard let self else { return }
                let totalBuffers = buffers.count
                guard totalBuffers > 0 else {
                    isSpeaking = false
                    return
                }

                for (i, buf) in buffers.enumerated() {
                    let charOffset = Int((Float(i) / Float(totalBuffers)) * Float(speechText.utf16.count))
                    pcmCallback?(buf, charOffset)
                }

                do {
                    try audioEngine.start()
                    for buf in buffers {
                        playerNode.scheduleBuffer(buf, at: nil, options: .interruptsAtLoop, completionHandler: nil)
                    }
                    playerNode.play()
                } catch {
                    isSpeaking = false
                }
            }
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        playerNode.stop()
        audioEngine.stop()
        isSpeaking = false
        pcmCallback = nil
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
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
