import Foundation

enum ExpressionPreset: String, CaseIterable {
    case neutral, warm, amused, thoughtful, curious
    case concerned, playful, serious, excited, sympathetic

    static func from(_ emotion: String) -> ExpressionPreset {
        ExpressionPreset(rawValue: emotion.lowercased()) ?? .neutral
    }
}

struct BlendShapeWeights {
    let browInnerUp: Float
    let browDown: Float
    let mouthSmile: Float
    let mouthOpen: Float
    let eyeWide: Float
    let jawOpen: Float

    static let neutral = BlendShapeWeights(
        browInnerUp: 0, browDown: 0, mouthSmile: 0,
        mouthOpen: 0, eyeWide: 0, jawOpen: 0
    )

    static let warm = BlendShapeWeights(
        browInnerUp: 0.2, browDown: 0, mouthSmile: 0.5,
        mouthOpen: 0.1, eyeWide: 0.3, jawOpen: 0
    )

    static let amused = BlendShapeWeights(
        browInnerUp: 0.1, browDown: 0, mouthSmile: 0.7,
        mouthOpen: 0.2, eyeWide: 0.2, jawOpen: 0.1
    )

    static let thoughtful = BlendShapeWeights(
        browInnerUp: 0.3, browDown: 0.1, mouthSmile: -0.1,
        mouthOpen: 0, eyeWide: 0.1, jawOpen: 0
    )

    static func weights(for emotion: String) -> BlendShapeWeights {
        switch ExpressionPreset.from(emotion) {
        case .warm: return .warm
        case .amused: return .amused
        case .thoughtful: return .thoughtful
        case .curious: return BlendShapeWeights(
            browInnerUp: 0.4, browDown: 0, mouthSmile: 0.1,
            mouthOpen: 0.1, eyeWide: 0.5, jawOpen: 0)
        case .excited: return BlendShapeWeights(
            browInnerUp: 0.3, browDown: 0, mouthSmile: 0.6,
            mouthOpen: 0.3, eyeWide: 0.6, jawOpen: 0.2)
        case .serious: return BlendShapeWeights(
            browInnerUp: 0, browDown: 0.3, mouthSmile: -0.2,
            mouthOpen: 0, eyeWide: 0, jawOpen: 0)
        default: return .neutral
        }
    }
}
