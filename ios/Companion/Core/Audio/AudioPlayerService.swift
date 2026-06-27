import Foundation
import AVFoundation
import CryptoKit

@MainActor
class AudioPlayerService {
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var isPlaying = false
    @Published private(set) var averagePower: Float = 0

    private static let bufferCache = NSCache<NSString, AVAudioPCMBuffer>()

    init() {
        setupAudioSession()
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
        installTap()
    }

    private func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func installTap() {
        let format = audioEngine.mainMixerNode.outputFormat(forBus: 0)
        audioEngine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let channelData = buffer.floatChannelData?.pointee else { return }
            let frames = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<frames {
                let sample = channelData[i]
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(frames))
            Task { @MainActor [weak self] in
                self?.averagePower = rms.isFinite ? min(rms * 5, 1) : 0
            }
        }
    }

    func playChunk(base64Data: String) {
        let cacheKey = NSString(string: String(base64Data.prefix(64)))

        if let cached = Self.bufferCache.object(forKey: cacheKey) {
            scheduleAndPlay(cached)
            return
        }

        guard let data = Data(base64Encoded: base64Data),
              let buffer = decodeAudioData(data) else { return }

        Self.bufferCache.setObject(buffer, forKey: cacheKey)
        scheduleAndPlay(buffer)
    }

    private func scheduleAndPlay(_ buffer: AVAudioPCMBuffer) {
        if !audioEngine.isRunning {
            try? audioEngine.start()
        }

        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        if !playerNode.isPlaying {
            playerNode.play()
            isPlaying = true
        }
    }

    func stop() {
        playerNode.stop()
        audioEngine.stop()
        isPlaying = false
        averagePower = 0
    }

    var isCurrentlyPlaying: Bool { isPlaying }

    private func decodeAudioData(_ data: Data) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: 44100,
                                         channels: 1,
                                         interleaved: false) else { return nil }
        let frameLength = UInt32(data.count) / format.streamDescription.pointee.mBytesPerFrame
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                           frameCapacity: frameLength) else { return nil }
        buffer.frameLength = frameLength
        data.withUnsafeBytes { src in
            buffer.floatChannelData?.pointee.assign(from: src.bindMemory(to: Float.self).baseAddress!,
                                                    count: Int(frameLength))
        }
        return buffer
    }
}
