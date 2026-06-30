import SwiftUI
import AVFoundation
import SceneKit
import UIKit

@MainActor
final class AvatarViewModel: ObservableObject {
    // MARK: - Published state for SwiftUI

    @Published var currentEmotion: Emotion = .neutral
    @Published var mouthOpen: Float = 0
    @Published var gazeTarget: GazeTarget = .camera
    @Published var isSpeaking = false
    @Published var isListening = false
    @Published var isThinking = false
    @Published var appearanceAttributes: [(String, String)] = []
    @Published var referenceImageData: Data?
    @Published var stage: String = "acquaintance"
    @Published var debugState = AvatarDebugState()
    @Published var errorMessage: String?

    // MARK: - Owned subsystems

    let controller: SceneKitAvatarController
    private(set) lazy var idleSystem = IdleLifeSystem(controller: controller)
    private(set) lazy var lipSyncSystem = LipSyncSystem(controller: controller)
    private(set) lazy var emotionSystem = EmotionSystem(controller: controller)
    private(set) lazy var gazeSystem = GazeSystem(controller: controller)
    private(set) lazy var gestureSystem = GestureSystem(controller: controller)
    private(set) lazy var performanceDirector = PerformanceDirector(
        emotionSystem: emotionSystem,
        gestureSystem: gestureSystem,
        gazeSystem: gazeSystem,
        lipSyncSystem: lipSyncSystem,
        profile: profile
    )
    private(set) lazy var wardrobeSystem = WardrobeSystem(controller: controller)
    private(set) lazy var secondaryMotion = SecondaryMotionSystem(controller: controller)
    private(set) lazy var reactivity = ReactivitySystem(
        controller: controller,
        emotionSystem: emotionSystem,
        gestureSystem: gestureSystem
    )

    private var profile: PersonalityMotionProfile = .from(traits: [], stage: "acquaintance")
    private var personalityTraits: [(String, Double)] = []
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0

    // MARK: - PCM / lip sync state

    private var pcmEnergies: [Float] = []
    private var totalEstimatedDuration: TimeInterval = 0
    private var speechStartTime: TimeInterval = 0

    // MARK: - Init

    private var reduceMotionObserver: NSObjectProtocol?

    init() {
        controller = SceneKitAvatarController()
        startDisplayLink()
        emotionSystem.setEmotion(.neutral, intensity: 0, duration: 0)
        controller.setReduceMotion(UIAccessibility.isReduceMotionEnabled)
        reduceMotionObserver = NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            let reduce = UIAccessibility.isReduceMotionEnabled
            self?.idleSystem.setEnabled(!reduce)
            self?.controller.setReduceMotion(reduce)
        }
    }

    deinit {
        displayLink?.invalidate()
        if let observer = reduceMotionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Lifecycle

    func start() {
        idleSystem.setEnabled(!UIAccessibility.isReduceMotionEnabled)
        startDisplayLink()
    }

    func stop() {
        idleSystem.setEnabled(false)
        displayLink?.invalidate()
        displayLink = nil
    }

    // MARK: - Appearance

    func loadGLB(named glbName: String) async {
        guard let glbURL = Bundle.main.url(forResource: glbName, withExtension: "glb") else {
            errorMessage = "GLB file \(glbName).glb not found in bundle"
            return
        }
        let descriptor = AvatarDescriptor(
            glbURL: glbURL,
            rigMappingURL: Bundle.main.url(forResource: "RigMapping", withExtension: "json")
        )
        do {
            try await controller.load(descriptor)
        } catch {
            errorMessage = "Failed to load GLB \(glbName): \(error.localizedDescription)"
        }
    }

    func applyAppearance(_ attributes: [(String, String)]) {
        appearanceAttributes = attributes
        controller.applyAppearance(attributes)
        rebuildProfile()
    }

    func setPersonalityTraits(_ traits: [(String, Double)]) {
        personalityTraits = traits
        rebuildProfile()
    }

    func applyReferenceImage(_ data: Data?) {
        referenceImageData = data
        guard let data, let image = UIImage(data: data) else { return }
        controller.applyReferenceImage(image)
    }

    // MARK: - Performance / Speech

    func setPCMEnergies(_ energies: [Float], duration: TimeInterval) {
        pcmEnergies = energies
        totalEstimatedDuration = duration
    }

    func beginSpeaking(text: String, track: PerformanceTrack?) {
        isSpeaking = true
        isThinking = false
        idleSystem.setEnabled(false)
        performanceDirector.beginPerformance(text: text, track: track)
        controller.setViseme(.sil, weight: 0)
        speechStartTime = CACurrentMediaTime()
    }

    func updateSpeechRange(characterRange: NSRange, text: String) {
        performanceDirector.updateSpeechRange(characterRange: characterRange, text: text)
        // Energy is now sampled from the display link tick against the playback clock
    }

    func endSpeaking() {
        isSpeaking = false
        performanceDirector.endPerformance()
        idleSystem.setEnabled(true)
        mouthOpen = 0
        pcmEnergies = []
    }

    func setThinking(_ thinking: Bool) {
        isThinking = thinking
        gazeSystem.setThinking(thinking)
    }

    func setListening(_ listening: Bool) {
        isListening = listening
        gazeSystem.setListening(listening)
        if listening {
            idleSystem.setEnabled(false)
        } else if !isSpeaking {
            idleSystem.setEnabled(true)
        }
    }

    func setStage(_ newStage: String) {
        stage = newStage
        reactivity.setStage(newStage)
        rebuildProfile()
    }

    // MARK: - Movement commands

    /// Performs a named movement immediately (used for direct user commands like "twirl").
    func performMovement(_ gesture: Gesture) {
        gestureSystem.playGesture(gesture)
    }

    /// A brief attentive reaction when the user sends a message: look over, warm up, and
    /// give a small acknowledging nod, then settle back unless a reply has started.
    func reactToUserMessage() {
        guard !isSpeaking else { return }
        gazeSystem.overrideGaze(.user)
        emotionSystem.setEmotion(.warm, intensity: 0.45, duration: 0.25)
        gestureSystem.playGesture(.nod)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { [weak self] in
            guard let self, !self.isSpeaking else { return }
            self.gazeSystem.overrideGaze(nil)
            self.emotionSystem.resetToNeutral(duration: 0.4)
        }
    }

    // MARK: - Tap handling

    func handleTap() {
        reactivity.onTap()
    }

    // MARK: - Display link tick

    private func startDisplayLink() {
        displayLink?.invalidate()
        let link = CADisplayLink(target: self, selector: #selector(tick(displayLink:)))
        link.add(to: .current, forMode: .common)
        displayLink = link
        lastTimestamp = CACurrentMediaTime()
    }

    @objc private func tick(displayLink: CADisplayLink) {
        let now = CACurrentMediaTime()
        let dt = now - lastTimestamp
        lastTimestamp = now
        // Drive the controller every frame. The controller decides what to animate:
        // the GLB skeleton stays alive (breathing/blink/gaze/gestures) regardless of
        // the idle flag, while the procedural fallback still honors `isIdleEnabled`.
        controller.tick(dt)
        tickLipSync()
    }

    private func tickLipSync() {
        guard isSpeaking else { return }

        // Path A: real PCM data has arrived — time-based sampling
        if !pcmEnergies.isEmpty, totalEstimatedDuration > 0 {
            let elapsed = CACurrentMediaTime() - speechStartTime
            let sampleInterval = totalEstimatedDuration / TimeInterval(pcmEnergies.count)
            let idx = Int(elapsed / sampleInterval)
            guard idx >= 0, idx < pcmEnergies.count else { return }
            let energy = pcmEnergies[idx]
            lipSyncSystem.enqueueEnergy(energy, timestamp: CACurrentMediaTime())
            return
        }

        // Path B: synthesis hasn't completed yet — vowel-counting fallback
        // gives visible mouth movement during the ~500ms pre-PCM window.
        let snippet = performanceDirector.currentSpeechSnippet()
        guard !snippet.isEmpty else { return }
        let vowels = snippet.lowercased().filter { "aeiou".contains($0) }.count
        let energy = min(Float(vowels) / Float(max(snippet.count, 1)) * 1.5, 1.0)
        lipSyncSystem.enqueueEnergy(energy, timestamp: CACurrentMediaTime())
    }

    // MARK: - Internal

    private func rebuildProfile() {
        profile = PersonalityMotionProfile.from(traits: personalityTraits, stage: stage)
        emotionSystem.setResting(profile.restingEmotion)
    }

    // MARK: - Debug

    func debugPlayEmotion(_ emotion: Emotion) {
        emotionSystem.setEmotion(emotion, intensity: 1.0, duration: 0.3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.emotionSystem.resetToNeutral(duration: 0.3)
        }
    }

    func debugPlayGesture(_ gesture: Gesture) {
        gestureSystem.playGesture(gesture)
    }

    func debugSetGaze(_ target: GazeTarget) {
        gazeSystem.overrideGaze(target)
    }
}
