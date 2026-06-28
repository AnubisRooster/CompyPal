import Foundation
import SceneKit
import UIKit

// MARK: - Bounded vocabularies (AVATAR_SPEC §4)

enum Viseme: String, Codable, CaseIterable {
    case sil, aa, ih, ou, ee, oh
}

enum Emotion: String, Codable, CaseIterable {
    case neutral, warm, happy, sad, surprised, concerned, playful, thoughtful, affectionate
}

enum Gesture: String, Codable, CaseIterable {
    case idle, nod, shakeHead = "shake_head", tiltHead = "tilt_head"
    case leanIn = "lean_in", leanBack = "lean_back", shrug, wave
    case handToChest = "hand_to_chest", think, laugh
}

enum GazeTarget: String, Codable {
    case camera, user, away, idle
}

// MARK: - WardrobeSlot — open set, deserialized from any string

struct WardrobeSlot: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }

    static let top = WardrobeSlot(rawValue: "top")
    static let bottom = WardrobeSlot(rawValue: "bottom")
    static let fullBody = WardrobeSlot(rawValue: "fullBody")
    static let footwear = WardrobeSlot(rawValue: "footwear")
    static let headwear = WardrobeSlot(rawValue: "headwear")
    static let outerwear = WardrobeSlot(rawValue: "outerwear")
    static let accessory = WardrobeSlot(rawValue: "accessory")
}

struct GarmentAsset: Codable, Hashable, Sendable {
    let id: String
    let name: String
    let glbName: String
    let slot: WardrobeSlot
    let bodyMask: Set<String>
}

// MARK: - RigMapping (AVATAR_SPEC §8)

struct RigMapping: Codable {
    let skeleton: [String: String]
    let visemes: [String: String]
    let blink: BlinkMapping
    let emotions: [String: [String: Float]]
    let gestures: [String: String]
    let wardrobe: WardrobeMapping

    struct BlinkMapping: Codable {
        let left: String
        let right: String
    }

    struct WardrobeMapping: Codable {
        let slots: [String]
        let bodyRegions: [String]
    }
}

// MARK: - AvatarDescriptor

struct AvatarDescriptor {
    let glbURL: URL?
    let rigMappingURL: URL?
}

// MARK: - Performance track (AVATAR_SPEC §7)

struct PerformanceTrack: Codable, Sendable {
    var text: String
    var emotion: String
    var beats: [PerformanceBeat]?
}

struct PerformanceBeat: Codable, Sendable {
    let at: Int
    let emotion: String?
    let gesture: String?
    let gaze: String?
}

// MARK: - AvatarController protocol (AVATAR_SPEC §3)

protocol AvatarController: AnyObject {
    var sceneView: SCNView { get }

    func load(_ descriptor: AvatarDescriptor) async throws
    func applyAppearance(_ attributes: [(String, String)])
    func applyReferenceImage(_ image: UIImage)
    func attachGarment(_ garment: GarmentAsset) async throws
    func detachGarment(slot: WardrobeSlot)
    func setViseme(_ viseme: Viseme, weight: Float)
    func setEmotion(_ emotion: Emotion, intensity: Float, blendDuration: TimeInterval)
    func playGesture(_ gesture: Gesture)
    func setGaze(_ target: GazeTarget)
    func setIdle(_ enabled: Bool)
    func tick(_ dt: TimeInterval)
}

// MARK: - PersonalityMotionProfile (AVATAR_SPEC §5)

struct PersonalityMotionProfile {
    let blinkRate: Float
    let idleAmplitude: Float
    let gestureFrequency: Float
    let motionSpeed: Float
    let restingEmotion: Emotion

    static func from(traits: [(String, Double)], stage: String) -> PersonalityMotionProfile {
        let traitMap = Dictionary(uniqueKeysWithValues: traits.map { ($0.0, $0.1) })

        let synonymGroups: [(String, [String])] = [
            ("friendly", ["friendly", "warm", "affectionate", "kind"]),
            ("energetic", ["energetic", "curious", "playful", "witty"]),
            ("thoughtful", ["thoughtful", "calm", "wise", "serious"]),
        ]

        func resolve(_ key: String, _ groups: [(String, [String])]) -> Double {
            for (canonical, synonyms) in groups {
                if canonical == key || synonyms.contains(key) {
                    return traitMap[key] ?? traitMap[canonical] ?? 0.5
                }
            }
            return traitMap[key] ?? 0.5
        }

        let friendliness = resolve("friendly", synonymGroups)
        let energy = resolve("energetic", synonymGroups)
        let thoughtfulness = resolve("thoughtful", synonymGroups)

        let isClose = stage == "friend" || stage == "confidant"

        return PersonalityMotionProfile(
            blinkRate: 0.05 - Float(energy) * 0.02,
            idleAmplitude: Float(energy) * 0.5 + 0.2,
            gestureFrequency: Float(friendliness) * 0.3 + (isClose ? 0.1 : 0),
            motionSpeed: Float(energy) * 0.5 + 0.5,
            restingEmotion: friendliness > 0.7 ? .warm : (thoughtfulness > 0.6 ? .thoughtful : .neutral)
        )
    }
}

// MARK: - Facial expression preset helpers

struct ExpressionWeights {
    let morphs: [String: Float]
}

extension Emotion {
    func arkitWeights() -> ExpressionWeights {
        switch self {
        case .neutral:
            return ExpressionWeights(morphs: [:])
        case .warm:
            return ExpressionWeights(morphs: ["mouthSmileLeft": 0.3, "mouthSmileRight": 0.3, "browInnerUp": 0.1])
        case .happy:
            return ExpressionWeights(morphs: ["mouthSmileLeft": 0.7, "mouthSmileRight": 0.7, "cheekSquintLeft": 0.4, "cheekSquintRight": 0.4])
        case .sad:
            return ExpressionWeights(morphs: ["mouthFrownLeft": 0.5, "mouthFrownRight": 0.5, "browInnerUp": 0.6])
        case .surprised:
            return ExpressionWeights(morphs: ["eyeWideLeft": 0.6, "eyeWideRight": 0.6, "browInnerUp": 0.6, "browOuterUpLeft": 0.5, "browOuterUpRight": 0.5, "jawOpen": 0.3])
        case .concerned:
            return ExpressionWeights(morphs: ["browInnerUp": 0.5, "browDownLeft": 0.2, "browDownRight": 0.2, "mouthFrownLeft": 0.2, "mouthFrownRight": 0.2])
        case .playful:
            return ExpressionWeights(morphs: ["mouthSmileLeft": 0.5, "browOuterUpLeft": 0.3, "eyeSquintLeft": 0.2])
        case .thoughtful:
            return ExpressionWeights(morphs: ["browDownLeft": 0.3, "browDownRight": 0.3, "mouthPucker": 0.2])
        case .affectionate:
            return ExpressionWeights(morphs: ["mouthSmileLeft": 0.4, "mouthSmileRight": 0.4, "eyeSquintLeft": 0.3, "eyeSquintRight": 0.3, "browInnerUp": 0.2])
        }
    }
}

// MARK: - Performance track parsing

struct PerformanceTrackParser {
    static func parse(raw: String) -> PerformanceTrack? {
        guard let start = raw.firstIndex(of: "{"),
              let end = raw[start...].balancedClose()
        else { return nil }
        let jsonChunk = raw[start...end]
        guard let data = jsonChunk.data(using: .utf8),
              var track = try? JSONDecoder().decode(PerformanceTrack.self, from: data)
        else { return nil }

        if Emotion(rawValue: track.emotion) == nil {
            track.emotion = "neutral"
        }

        if let beats = track.beats {
            track.beats = beats.filter { beat in
                if let em = beat.emotion, Emotion(rawValue: em) == nil { return false }
                if let g = beat.gesture, Gesture(rawValue: g) == nil { return false }
                return true
            }
        }

        return track
    }

    static func extract(from reply: String) -> (clean: String, track: PerformanceTrack?) {
        // Strategy 1: look for PERFORMANCE: prefix + JSON
        if let range = reply.range(of: "PERFORMANCE:"),
           let start = reply[range.upperBound...].firstIndex(of: "{"),
           let end = reply[range.upperBound...].balancedClose(from: start) {
            let jsonChunk = String(reply[start...end])
            let clean = reply[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            let track = parse(raw: jsonChunk)
            return (clean, track)
        }

        // Strategy 2: try any balanced JSON block with text+emotion keys
        if let start = reply.firstIndex(of: "{"),
           let end = reply[start...].balancedClose() {
            let jsonChunk = String(reply[start...end])
            if let data = jsonChunk.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               obj["text"] as? String != nil,
               obj["emotion"] as? String != nil {
                let clean = (reply[..<start] + (reply[end...].dropFirst())).trimmingCharacters(in: .whitespacesAndNewlines)
                let track = parse(raw: jsonChunk)
                return (clean, track)
            }
        }

        return (reply, nil)
    }
}

// MARK: - Debug panel type (Phase A0 DoD)

struct AvatarDebugState {
    var selectedBlendshape: String = ""
    var blendshapeWeight: Float = 0
    var currentEmotion: Emotion = .neutral
    var currentGesture: Gesture = .idle
    var currentGaze: GazeTarget = .camera
    var isIdleEnabled = true
    var mouthOpen: Float = 0
}

extension StringProtocol {
    func balancedClose(from start: Index? = nil) -> Index? {
        let searchStart = start ?? self.startIndex
        guard searchStart < endIndex, self[searchStart] == "{" else { return nil }
        var depth = 0
        var i = searchStart
        while i < endIndex {
            let ch = self[i]
            if ch == "{" { depth += 1 }
            else if ch == "}" { depth -= 1 }
            if depth == 0 { return i }
            formIndex(after: &i)
        }
        return nil
    }
}
