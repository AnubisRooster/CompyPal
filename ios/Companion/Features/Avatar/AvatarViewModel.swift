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
        let head = controller.sceneView.scene?.rootNode.childNode(withName: "procedural_head", recursively: true)
        head?.geometry?.materials.forEach { $0.diffuse.contents = image }
        head?.geometry?.materials.forEach { $0.roughness.contents = 0.8 }
    }

    // MARK: - Performance / Speech

    func beginSpeaking(text: String, track: PerformanceTrack?) {
        isSpeaking = true
        isThinking = false
        idleSystem.setEnabled(false)
        performanceDirector.beginPerformance(text: text, track: track)
        controller.setViseme(.sil, weight: 0)
    }

    func updateSpeechRange(characterRange: NSRange, text: String) {
        performanceDirector.updateSpeechRange(characterRange: characterRange, text: text)
    }

    func endSpeaking() {
        isSpeaking = false
        performanceDirector.endPerformance()
        idleSystem.setEnabled(true)
        mouthOpen = 0
    }

    func onSpeechProgress(mouthOpen value: Float) {
        mouthOpen = value
        let viseme: Viseme = value > 0.1 ? (value > 0.5 ? .aa : .oh) : .sil
        controller.setViseme(viseme, weight: min(value, 1.0))
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
