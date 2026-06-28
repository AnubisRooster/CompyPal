import Foundation
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
}
