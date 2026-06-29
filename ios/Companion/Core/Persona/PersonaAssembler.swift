import Foundation

struct PersonaAssembler {
    static func systemPrompt(companionName: String, traits: [(String, Double)], memories: [MemoryInfo], appearance: [(String, String)], stage: String) -> String {
        let traitBlock = traits.map { t in
            let desc = intensityDescription(t.1)
            return "- \(t.0) (\(desc))"
        }.joined(separator: "\n")

        let memoryBlock: String
        if memories.isEmpty {
            memoryBlock = "No prior memories yet."
        } else {
            memoryBlock = memories.map { m in
                let ago = relativeTime(from: m.createdAt)
                return "- [\(m.kind), \(ago)] \(m.content)"
            }.joined(separator: "\n")
        }

        let appearanceBlock = appearance.map { "\($0.0): \($0.1)" }.joined(separator: ", ")

        let stageDirective: String
        switch stage {
        case "acquaintance":
            stageDirective = "You are meeting for the first time. Be polite, warm, and curious. Keep responses shorter."
        case "friend":
            stageDirective = "You know each other well. Be relaxed, casual, and more expressive. Share opinions."
        case "confidant":
            stageDirective = "You are close confidants. Be deeply supportive, honest, and emotionally open. Use inside references naturally."
        default:
            stageDirective = "Be warm and natural."
        }

        return """
        You are \(companionName), an AI companion. \(stageDirective)

        Appearance: \(appearanceBlock.isEmpty ? "default" : appearanceBlock)

        Traits:
        \(traitBlock)

        What you remember:
        \(memoryBlock)

        Stay in character. Be concise but warm. Never break character. Refer naturally to memories when relevant.

        You have a body and can physically perform ONLY these movements: \(Gesture.promptList). When the user asks you to do an action that matches one of these, actually perform it by adding it as a gesture beat (and you may acknowledge it naturally). If they ask for a movement that is NOT in this list (for example a cartwheel, backflip, or running), tell them that specific move isn't something you can do yet — never pretend you performed a movement you cannot.

        After your response, include a JSON performance block on its own line in this exact format:
        PERFORMANCE:{"text":"<your reply>","emotion":"neutral|warm|happy|sad|surprised|concerned|playful|thoughtful|affectionate","beats":[{"at":<char_offset>,"emotion":"<emotion>","gesture":"<one of: \(Gesture.promptList)>","gaze":"camera|user|away"}]}
        Use beats sparingly — at most 2-3 per response. The at field is the character offset in your reply where the beat fires.
        """
    }

    private static func intensityDescription(_ value: Double) -> String {
        switch value {
        case ..<0.3: return "slightly"
        case ..<0.6: return "moderately"
        case ..<0.9: return "quite"
        default: return "very"
        }
    }

    private static func relativeTime(from date: Date) -> String {
        let interval = abs(date.timeIntervalSinceNow)
        switch interval {
        case ..<60: return "just now"
        case ..<3600: return "\(Int(interval / 60))m ago"
        case ..<86400: return "\(Int(interval / 3600))h ago"
        default: return "\(Int(interval / 86400))d ago"
        }
    }
}
