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

    func speak(_ text: String, voiceId: String = "com.apple.voice.compact.en-US.Samantha", pitch: Double = 1.0, rate: Double = 0.5, rangeCallback: ((NSRange) -> Void)? = nil, energiesCallback: (([Float], TimeInterval) -> Void)? = nil, completion: (() -> Void)? = nil) {
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

        // Synthesize PCM energies in the background — they arrive asynchronously
        let voiceCopy = utterance.voice
        let pitchCopy = utterance.pitchMultiplier
        let rateCopy = utterance.rate
        let textCopy = text
        let capturedCallback = energiesCallback
        Task.detached(priority: .userInitiated) {
            let writeUtterance = AVSpeechUtterance(string: textCopy)
            writeUtterance.voice = voiceCopy
            writeUtterance.pitchMultiplier = pitchCopy
            writeUtterance.rate = rateCopy

            let synth = AVSpeechSynthesizer()
            var buffers: [AVAudioPCMBuffer] = []
            synth.write(writeUtterance) { buffer in
                if let pcm = buffer as? AVAudioPCMBuffer, pcm.frameLength > 0 {
                    buffers.append(pcm)
                }
            }
            guard !buffers.isEmpty else { return }
            let concatenated = Self.concatenateBuffers(buffers)
            let energies = Self.computePCMEnergies(concatenated)
            let duration = TimeInterval(concatenated.frameLength) / concatenated.format.sampleRate
            await MainActor.run {
                capturedCallback?(energies, duration)
            }
        }
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

    // MARK: - Buffer processing (safe to call off main)

    nonisolated static func concatenateBuffers(_ buffers: [AVAudioPCMBuffer]) -> AVAudioPCMBuffer {
        if buffers.isEmpty { fatalError("empty buffer list") }
        if buffers.count == 1 { return buffers[0] }
        let totalFrames = buffers.reduce(0) { $0 + Int($1.frameLength) }
        let format = buffers[0].format
        guard format.commonFormat == .pcmFormatFloat32,
              let result = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames))
        else { return buffers[0] }
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

    nonisolated static func computePCMEnergies(_ buffer: AVAudioPCMBuffer) -> [Float] {
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
            energies.append(min(avg * 5, 1.0))
            pos = end
        }
        return energies
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
        completion?()
    }
}
