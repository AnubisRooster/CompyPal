import AVFoundation

struct VoicePicker {
    private static var cachedVoices: [AVSpeechSynthesisVoice] = {
        AVSpeechSynthesisVoice.speechVoices()
    }()

    static func selectVoice() -> String {
        let enVoices = cachedVoices.filter { $0.language.hasPrefix("en") }
        return enVoices.first?.identifier ?? "com.apple.voice.compact.en-US.Samantha"
    }

    static func selectVoice(gender: AVSpeechSynthesisVoiceGender) -> String {
        let match = cachedVoices.first { $0.language.hasPrefix("en") && $0.gender == gender }
        return match?.identifier ?? selectVoice()
    }

    static func refreshCache() {
        cachedVoices = AVSpeechSynthesisVoice.speechVoices()
    }
}
