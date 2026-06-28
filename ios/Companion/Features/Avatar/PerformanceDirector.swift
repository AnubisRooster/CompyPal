import Foundation
import AVFoundation

@MainActor
final class PerformanceDirector {
    private let emotionSystem: EmotionSystem
    private let gestureSystem: GestureSystem
    private let gazeSystem: GazeSystem
    private let lipSyncSystem: LipSyncSystem
    private let profile: PersonalityMotionProfile

    private var currentTrack: PerformanceTrack?
    private var isPerforming = false
    private var pendingBeats: [(at: Int, emotion: Emotion?, gesture: Gesture?, gaze: GazeTarget?)] = []

    init(
        emotionSystem: EmotionSystem,
        gestureSystem: GestureSystem,
        gazeSystem: GazeSystem,
        lipSyncSystem: LipSyncSystem,
        profile: PersonalityMotionProfile
    ) {
        self.emotionSystem = emotionSystem
        self.gestureSystem = gestureSystem
        self.gazeSystem = gazeSystem
        self.lipSyncSystem = lipSyncSystem
        self.profile = profile
    }

    func beginPerformance(text: String, track: PerformanceTrack?) {
        isPerforming = true
        lipSyncSystem.beginSpeaking()

        if let track {
            currentTrack = track

            // Set primary emotion
            if let primaryEmotion = Emotion(rawValue: track.emotion) {
                emotionSystem.setEmotion(primaryEmotion, intensity: 1.0, duration: 0.3)
            } else {
                emotionSystem.setEmotion(profile.restingEmotion, intensity: 0.5, duration: 0.3)
            }

            // Schedule beats
            if let beats = track.beats {
                pendingBeats = beats.map { beat in
                    (
                        at: beat.at,
                        emotion: beat.emotion.flatMap { Emotion(rawValue: $0) },
                        gesture: beat.gesture.flatMap { Gesture(rawValue: $0) },
                        gaze: beat.gaze.flatMap { GazeTarget(rawValue: $0) }
                    )
                }
            }

            gazeSystem.overrideGaze(.user)
        } else {
            // No track — neutral performance
            emotionSystem.setEmotion(profile.restingEmotion, intensity: 0.5, duration: 0.3)
            gazeSystem.overrideGaze(.camera)
        }
    }

    func updateSpeechRange(characterRange: NSRange, text: String) {
        guard isPerforming else { return }

        // Fire beats at matching character offsets
        let location = characterRange.location
        let matching = pendingBeats.filter { $0.at >= location - 2 && $0.at <= location + 2 }
        for beat in matching {
            if let emotion = beat.emotion {
                emotionSystem.setEmotion(emotion, intensity: 1.0, duration: 0.2)
            }
            if let gesture = beat.gesture {
                gestureSystem.playGesture(gesture)
            }
            if let gaze = beat.gaze {
                gazeSystem.overrideGaze(gaze)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.gazeSystem.overrideGaze(.user)
                }
            }
        }
        pendingBeats.removeAll { $0.at >= location - 2 && $0.at <= location + 2 }
    }

    func endPerformance() {
        isPerforming = false
        lipSyncSystem.stopSpeaking()
        emotionSystem.resetToNeutral(duration: 0.5)
        gazeSystem.overrideGaze(nil)
        pendingBeats.removeAll()
        currentTrack = nil
    }
}
