import SwiftUI
import AVFoundation
import SceneKit

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

    // MARK: - Init

    init() {
        controller = SceneKitAvatarController()
        startDisplayLink()
        emotionSystem.setEmotion(.neutral, intensity: 0, duration: 0)
    }

    deinit {
        displayLink?.invalidate()
    }

    // MARK: - Lifecycle

    func start() {
        idleSystem.setEnabled(true)
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

    private var pcmEnergies: [Float] = []

    func beginSpeaking(text: String, track: PerformanceTrack?, pcmEnergies: [Float] = []) {
        isSpeaking = true
        isThinking = false
        idleSystem.setEnabled(false)
        performanceDirector.beginPerformance(text: text, track: track)
        controller.setViseme(.sil, weight: 0)
        self.pcmEnergies = pcmEnergies
    }

    func updateSpeechRange(characterRange: NSRange, text: String) {
        performanceDirector.updateSpeechRange(characterRange: characterRange, text: text)
        let energy = energyForRange(characterRange, text: text)
        lipSyncSystem.enqueueEnergy(energy, timestamp: CACurrentMediaTime())
    }

    private func energyForRange(_ range: NSRange, text: String) -> Float {
        if !pcmEnergies.isEmpty {
            let progress = Double(range.location) / Double(max(text.count, 1))
            let idx = min(Int(progress * Double(pcmEnergies.count)), pcmEnergies.count - 1)
            return idx >= 0 ? pcmEnergies[idx] : 0
        }
        guard let swiftRange = Range(range, in: text) else { return 0 }
        let snippet = text[swiftRange].lowercased()
        let vowelCount = snippet.filter { "aeiou".contains($0) }.count
        let total = max(snippet.count, 1)
        return min(Float(vowelCount) / Float(total) * 1.5, 1.0)
    }

    func endSpeaking() {
        isSpeaking = false
        performanceDirector.endPerformance()
        idleSystem.setEnabled(true)
        mouthOpen = 0
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
        idleSystem.tick(dt)
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
