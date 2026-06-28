import Foundation
import AVFoundation

@MainActor
class TTSEngine: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private let writeSynthesizer = AVSpeechSynthesizer()
    private var rangeCallback: ((NSRange, [Float]) -> Void)?
    private var pcmEnergies: [Float] = []
    private var completion: (() -> Void)?

    @Published private(set) var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, voiceId: String = "com.apple.voice.compact.en-US.Samantha", pitch: Double = 1.0, rate: Double = 0.5, rangeCallback: ((NSRange, [Float]) -> Void)? = nil, completion: (() -> Void)? = nil) {
        stop()
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Pre-compute PCM energy from a write-synthesized buffer
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId) ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.pitchMultiplier = Float(pitch)
        utterance.rate = Float(rate)

        if let buffer = synthesizeToBuffer(utterance) {
            pcmEnergies = Self.computePCMEnergies(buffer)
        } else {
            pcmEnergies = []
        }

        self.rangeCallback = rangeCallback
        self.completion = completion

        let playUtterance = AVSpeechUtterance(string: text)
        playUtterance.voice = utterance.voice
        playUtterance.pitchMultiplier = Float(pitch)
        playUtterance.rate = Float(rate)
        playUtterance.volume = 1.0

        isSpeaking = true
        synthesizer.speak(playUtterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        completion = nil
    }

    private func synthesizeToBuffer(_ utterance: AVSpeechUtterance) -> AVAudioPCMBuffer? {
        var buffers: [AVAudioPCMBuffer] = []
        writeSynthesizer.write(utterance) { buffer in
            if let pcm = buffer as? AVAudioPCMBuffer, pcm.frameLength > 0 {
                buffers.append(pcm)
            }
        }
        guard !buffers.isEmpty else { return nil }
        if buffers.count == 1 { return buffers[0] }
        // Concatenate multiple buffers
        let totalFrames = buffers.reduce(0) { $0 + Int($1.frameLength) }
        let format = buffers[0].format
        guard let result = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames)) else { return nil }
        var offset = 0
        for buf in buffers {
            let frames = Int(buf.frameLength)
            let channelCount = Int(format.channelCount)
            for ch in 0..<channelCount {
                memcpy(result.floatChannelData?[ch].advanced(by: offset), buf.floatChannelData?[ch], frames * MemoryLayout<Float>.size)
            }
            offset += frames
        }
        result.frameLength = AVAudioFrameCount(totalFrames)
        return result
    }

    private static func computePCMEnergies(_ buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else { return [] }
        let frameLength = Int(buffer.frameLength)
        let channel = 0
        var energies: [Float] = []
        let chunkSize = 1024
        var pos = 0
        while pos < frameLength {
            let end = min(pos + chunkSize, frameLength)
            var sum: Float = 0
            let count = end - pos
            for i in pos..<end {
                let sample = abs(channelData[channel][i])
                sum += sample
            }
            let avg = sum / Float(count)
            let energy = min(avg * 5, 1.0)
            energies.append(energy)
            pos = end
        }
        return energies
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
        rangeCallback?(characterRange, pcmEnergies)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        completion?()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        completion?()
    }
}
