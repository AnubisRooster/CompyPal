import AVFoundation

struct VoicePicker {
    private static var cachedVoices: [AVSpeechSynthesisVoice] = {
        AVSpeechSynthesisVoice.speechVoices()
    }()

    static func selectVoice() -> String {
        selectVoice(gender: .female)
    }

    /// Picks the most natural-sounding installed English voice, preferring premium/enhanced
    /// neural voices (and the requested gender) over the robotic `compact` system default.
    /// Quality neural voices must be downloaded by the user in iOS Settings → Accessibility →
    /// Spoken Content → Voices; we gracefully fall back to whatever is available.
    static func selectVoice(gender: AVSpeechSynthesisVoiceGender) -> String {
        let enVoices = cachedVoices.filter { $0.language.hasPrefix("en") }
        guard !enVoices.isEmpty else { return "com.apple.voice.compact.en-US.Samantha" }

        func qualityRank(_ v: AVSpeechSynthesisVoice) -> Int {
            switch v.quality {
            case .premium: return 3
            case .enhanced: return 2
            default: return 1
            }
        }
        // Prefer the requested gender, then highest quality, then en-US.
        let best = enVoices.max { a, b in
            let ga = (a.gender == gender) ? 1 : 0
            let gb = (b.gender == gender) ? 1 : 0
            if ga != gb { return ga < gb }
            if qualityRank(a) != qualityRank(b) { return qualityRank(a) < qualityRank(b) }
            let ra = a.language == "en-US" ? 1 : 0
            let rb = b.language == "en-US" ? 1 : 0
            return ra < rb
        }
        return best?.identifier ?? enVoices[0].identifier
    }

    static func refreshCache() {
        cachedVoices = AVSpeechSynthesisVoice.speechVoices()
    }
}
