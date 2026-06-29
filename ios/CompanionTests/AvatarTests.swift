import Foundation
import AVFoundation
import Testing
@testable import Companion

struct AvatarTests {
    // MARK: - PerformanceTrackParser

    @Test func extractWithPerformancePrefix() throws {
        let reply = "Hello there! PERFORMANCE:{\"text\":\"Hello there!\",\"emotion\":\"warm\",\"beats\":[{\"at\":3,\"gesture\":\"nod\"}]}"
        let (clean, track) = PerformanceTrackParser.extract(from: reply)
        #expect(clean == "Hello there!")
        #expect(track != nil)
        #expect(track?.emotion == "warm")
    }

    @Test func extractWithoutPrefix() throws {
        let reply = "Hi! {\"text\":\"Hi!\",\"emotion\":\"happy\"}"
        let (clean, track) = PerformanceTrackParser.extract(from: reply)
        #expect(clean == "Hi!")
        #expect(track != nil)
        #expect(track?.emotion == "happy")
    }

    @Test func extractNoTrack() throws {
        let reply = "Just a regular reply without any JSON."
        let (clean, track) = PerformanceTrackParser.extract(from: reply)
        #expect(clean == "Just a regular reply without any JSON.")
        #expect(track == nil)
    }

    @Test func extractWithFences() throws {
        let reply = "```json\n{\"text\":\"Hello!\",\"emotion\":\"playful\"}\n```"
        let (clean, track) = PerformanceTrackParser.extract(from: reply)
        #expect(track != nil)
        #expect(track?.emotion == "playful")
    }

    @Test func extractWithFencedPerformancePrefix() throws {
        let reply = "```json\nPERFORMANCE:{\"text\":\"Hey\",\"emotion\":\"surprised\"}\n```"
        let (clean, track) = PerformanceTrackParser.extract(from: reply)
        #expect(track != nil)
        #expect(track?.emotion == "surprised")
    }

    @Test func extractEmptyBeatsFiltered() throws {
        let reply = "Sure! {\"text\":\"Sure!\",\"emotion\":\"neutral\",\"beats\":[{\"at\":0,\"emotion\":\"neutral\"}]}"
        let (clean, track) = PerformanceTrackParser.extract(from: reply)
        #expect(track != nil)
        #expect(track?.beats?.count == 1)
    }

    @Test func extractInvalidEmotionDefaultsToNeutral() throws {
        let json = "{\"text\":\"Hi\",\"emotion\":\"unknown_emotion\"}"
        let track = PerformanceTrackParser.parse(raw: json)
        #expect(track?.emotion == "neutral")
    }

    @Test func parseInvalidJSONReturnsNil() throws {
        let track = PerformanceTrackParser.parse(raw: "not json at all")
        #expect(track == nil)
    }

    @Test func parseUnbalancedBracesReturnsNil() throws {
        let track = PerformanceTrackParser.parse(raw: "{\"text\":\"hi\"")
        #expect(track == nil)
    }

    // MARK: - PersonalityMotionProfile

    @Test func profileFromFriendlyTraits() throws {
        let traits: [(String, Double)] = [("friendly", 0.9)]
        let profile = PersonalityMotionProfile.from(traits: traits, stage: "acquaintance")
        #expect(profile.restingEmotion == .warm)
        #expect(profile.gestureFrequency > 0.2)
    }

    @Test func profileFromThoughtfulTraits() throws {
        let traits: [(String, Double)] = [("thoughtful", 0.9)]
        let profile = PersonalityMotionProfile.from(traits: traits, stage: "acquaintance")
        #expect(profile.restingEmotion == .thoughtful)
    }

    @Test func profileFromDefaultTraits() throws {
        let traits: [(String, Double)] = [("shy", 0.5)]
        let profile = PersonalityMotionProfile.from(traits: traits, stage: "acquaintance")
        #expect(profile.gestureFrequency >= 0)
    }

    @Test func profileCloseStageIncreasesGesture() throws {
        let traits: [(String, Double)] = [("friendly", 0.5)]
        let acquaintance = PersonalityMotionProfile.from(traits: traits, stage: "acquaintance")
        let confidant = PersonalityMotionProfile.from(traits: traits, stage: "confidant")
        #expect(confidant.gestureFrequency >= acquaintance.gestureFrequency)
    }

    // MARK: - Emotion ARKit weights

    @Test func neutralHasNoWeights() throws {
        let weights = Emotion.neutral.arkitWeights()
        #expect(weights.morphs.isEmpty)
    }

    @Test func happyHasSmile() throws {
        let weights = Emotion.happy.arkitWeights()
        #expect(weights.morphs["mouthSmileLeft"] == 0.7)
        #expect(weights.morphs["mouthSmileRight"] == 0.7)
    }

    @Test func surprisedHasWideEyes() throws {
        let weights = Emotion.surprised.arkitWeights()
        #expect(weights.morphs["eyeWideLeft"] == 0.6)
        #expect(weights.morphs["jawOpen"] == 0.3)
    }

    // MARK: - PCM energy computation

    @Test func computePCMEnergiesEmptyBuffer() throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 0)!
        buffer.frameLength = 0
        let energies = TTSEngine.computePCMEnergies(buffer)
        #expect(energies.isEmpty)
    }

    @Test func computePCMEnergiesSilence() throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4096)!
        buffer.frameLength = 4096
        let channelData = buffer.floatChannelData![0]
        for i in 0..<4096 { channelData[i] = 0 }
        let energies = TTSEngine.computePCMEnergies(buffer)
        #expect(!energies.isEmpty)
        for e in energies { #expect(e < 0.01) }
    }

    @Test func computePCMEnergiesFullScale() throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 2048)!
        buffer.frameLength = 2048
        let channelData = buffer.floatChannelData![0]
        for i in 0..<2048 { channelData[i] = 1.0 }
        let energies = TTSEngine.computePCMEnergies(buffer)
        #expect(!energies.isEmpty)
        // Full-scale samples produce energy clamped to 1.0
        for e in energies { #expect(e == 1.0) }
    }

    // MARK: - Buffer concatenation

    @Test func concatenateSingleBuffer() throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 100)!
        buffer.frameLength = 100
        let result = TTSEngine.concatenateBuffers([buffer])
        #expect(result.frameLength == 100)
    }

    @Test func concatenateMultipleBuffers() throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1)!
        let b1 = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 100)!
        b1.frameLength = 100
        let c1 = b1.floatChannelData![0]
        for i in 0..<100 { c1[i] = 0.5 }

        let b2 = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 50)!
        b2.frameLength = 50
        let c2 = b2.floatChannelData![0]
        for i in 0..<50 { c2[i] = 0.25 }

        let result = TTSEngine.concatenateBuffers([b1, b2])
        #expect(result.frameLength == 150)
        #expect(result.floatChannelData![0][0] == 0.5)
        #expect(result.floatChannelData![0][100] == 0.25)
        #expect(result.floatChannelData![0][149] == 0.25)
    }

    // MARK: - Morph name JSON extraction (simulates the three GLB locations)

    @Test func morphNameRecoveryMeshExtras() throws {
        // Simulates meshes[i].extras.targetNames (Riven's location)
        let json = """
        {
            "meshes": [
                { "extras": { "targetNames": ["Fcl_ALL_Neutral", "Fcl_MTH_A", "Fcl_EYE_Close_L"] } },
                { "name": "noMorphs" }
            ]
        }
        """.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: json) as! [String: Any]
        let meshes = obj["meshes"] as! [[String: Any]]
        var names: [String] = []
        for mesh in meshes {
            if let extras = mesh["extras"] as? [String: Any],
               let targetNames = extras["targetNames"] as? [String] {
                names = targetNames
                break
            }
        }
        #expect(names.count == 3)
        #expect(names[0] == "Fcl_ALL_Neutral")
        #expect(names[1] == "Fcl_MTH_A")
        #expect(names[2] == "Fcl_EYE_Close_L")
    }

    @Test func morphNameRecoveryPrimitiveExtras() throws {
        // Simulates meshes[i].primitives[j].extras.targetNames
        let json = """
        {
            "meshes": [
                {
                    "primitives": [
                        { "extras": { "targetNames": ["MTH_A", "MTH_I"] } }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: json) as! [String: Any]
        let meshes = obj["meshes"] as! [[String: Any]]
        var names: [String] = []
        for mesh in meshes {
            if let primitives = mesh["primitives"] as? [[String: Any]] {
                for primitive in primitives {
                    if let extras = primitive["extras"] as? [String: Any],
                       let targetNames = extras["targetNames"] as? [String] {
                        names = targetNames
                        break
                    }
                }
            }
        }
        #expect(names.count == 2)
        #expect(names[0] == "MTH_A")
    }

    @Test func morphNameRecoveryPerTargetExtras() throws {
        // Simulates meshes[i].primitives[j].targets[k].extras.targetNames
        let json = """
        {
            "meshes": [
                {
                    "primitives": [
                        {
                            "targets": [
                                { "extras": { "targetNames": ["blendShape1"] } },
                                { "extras": { "targetNames": ["blendShape2"] } }
                            ]
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: json) as! [String: Any]
        let meshes = obj["meshes"] as! [[String: Any]]
        var names: [String] = []
        for mesh in meshes {
            if let primitives = mesh["primitives"] as? [[String: Any]] {
                for primitive in primitives {
                    if let targets = primitive["targets"] as? [[String: Any]] {
                        for target in targets {
                            if let extras = target["extras"] as? [String: Any],
                               let tn = extras["targetNames"] as? [String],
                               let first = tn.first {
                                names.append(first)
                            }
                        }
                    }
                }
            }
        }
        #expect(names.count == 2)
        #expect(names[0] == "blendShape1")
        #expect(names[1] == "blendShape2")
    }

    // MARK: - RigMapping viseme validation

    @Test func rigMappingVisemeNamesMatchVRMConvention() throws {
        let json = """
        {
            "skeleton": {},
            "visemes": {
                "aa": "Fcl_MTH_A", "ih": "Fcl_MTH_I", "ou": "Fcl_MTH_U",
                "ee": "Fcl_MTH_E", "oh": "Fcl_MTH_O", "sil": "Fcl_MTH_Close"
            },
            "blink": { "left": "Fcl_EYE_Close_L", "right": "Fcl_EYE_Close_R" },
            "emotions": {},
            "gestures": {},
            "wardrobe": { "slots": [], "bodyRegions": [] }
        }
        """.data(using: .utf8)!
        let mapping = try JSONDecoder().decode(RigMapping.self, from: json)
        #expect(mapping.visemes["aa"] == "Fcl_MTH_A")
        #expect(mapping.visemes["ih"] == "Fcl_MTH_I")
        #expect(mapping.visemes["ou"] == "Fcl_MTH_U")
        #expect(mapping.visemes["ee"] == "Fcl_MTH_E")
        #expect(mapping.visemes["oh"] == "Fcl_MTH_O")
        #expect(mapping.visemes["sil"] == "Fcl_MTH_Close")
        #expect(mapping.blink.left == "Fcl_EYE_Close_L")
        #expect(mapping.blink.right == "Fcl_EYE_Close_R")
    }

    // MARK: - TTSEngine concatenation edge cases

    @Test func concatenateNonFloat32FormatReturnsFirstBuffer() throws {
        let intFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 22050, channels: 1, interleaved: false)!
        let b1 = AVAudioPCMBuffer(pcmFormat: intFormat, frameCapacity: 100)!
        b1.frameLength = 100
        let b2 = AVAudioPCMBuffer(pcmFormat: intFormat, frameCapacity: 50)!
        b2.frameLength = 50
        let result = TTSEngine.concatenateBuffers([b1, b2])
        #expect(result === b1, "Non-float32 format should return first buffer")
    }

    @Test func computePCMEnergiesNonFloat32ReturnsEmpty() throws {
        let intFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 22050, channels: 1, interleaved: false)!
        let buffer = AVAudioPCMBuffer(pcmFormat: intFormat, frameCapacity: 1024)!
        buffer.frameLength = 1024
        let energies = TTSEngine.computePCMEnergies(buffer)
        #expect(energies.isEmpty)
    }

    @Test func computePCMEnergiesPartialBuffer() throws {
        let format = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4096)!
        buffer.frameLength = 500
        let channelData = buffer.floatChannelData![0]
        for i in 0..<500 { channelData[i] = i < 250 ? 0 : 1.0 }
        let energies = TTSEngine.computePCMEnergies(buffer)
        #expect(!energies.isEmpty)
    }
}
