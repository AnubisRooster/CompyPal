import Foundation
import AVFoundation
import SceneKit

// MARK: - IdleLifeSystem (A1)

@MainActor
final class IdleLifeSystem {
    private weak var controller: AvatarController?
    private var isEnabled = true

    init(controller: AvatarController) {
        self.controller = controller
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        controller?.setIdle(enabled)
    }

    func tick(_ dt: TimeInterval) {
        guard isEnabled else { return }
        controller?.tick(dt)
    }
}

// MARK: - LipSyncSystem (A2)

@MainActor
final class LipSyncSystem {
    private weak var controller: AvatarController?
    private var isActive = false
    private var visemeQueue: [(Viseme, Float, TimeInterval)] = []
    private let engine = AVAudioEngine()
    private var lastViseme: Viseme = .sil
    private var smoothWeight: Float = 0

    init(controller: AvatarController) {
        self.controller = controller
    }

    func beginSpeaking() {
        isActive = true
        smoothWeight = 0
    }

    func stopSpeaking() {
        isActive = false
        visemeQueue.removeAll()
        controller?.setViseme(.sil, weight: 0)
    }

    func enqueueEnergy(_ energy: Float, timestamp: TimeInterval) {
        guard isActive else { return }
        let viseme = visemeForEnergy(energy)
        visemeQueue.append((viseme, energy, timestamp))
        processQueue()
        controller?.setViseme(viseme, weight: energy)
    }

    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard isActive else { return }
        guard let channelData = buffer.floatChannelData else { return }
        let frameLength = Int(buffer.frameLength)
        let channel = 0

        var sum: Float = 0
        for i in 0..<min(frameLength, 1024) {
            let sample = abs(channelData[channel][i])
            sum += sample
        }
        let avg = sum / Float(min(frameLength, 1024))
        let energy = min(avg * 5, 1.0)

        enqueueEnergy(energy, timestamp: CACurrentMediaTime())

        // Drive viseme on controller
        let viseme = visemeForEnergy(energy)
        controller?.setViseme(viseme, weight: energy)
    }

    private func visemeForEnergy(_ energy: Float) -> Viseme {
        if energy < 0.05 { return .sil }
        if energy < 0.2 { return .ih }
        if energy < 0.4 { return .ee }
        if energy < 0.6 { return .ou }
        if energy < 0.8 { return .aa }
        return .oh
    }

    private func processQueue() {
        guard visemeQueue.count > 3 else { return }
        let (viseme, weight, _) = visemeQueue.removeFirst()
        lastViseme = viseme
        smoothWeight = smoothWeight * 0.7 + weight * 0.3
    }
}

// MARK: - EmotionSystem (A4)

@MainActor
final class EmotionSystem {
    private weak var controller: AvatarController?
    private var currentEmotion: Emotion = .neutral
    private var targetEmotion: Emotion = .neutral
    private var blendDuration: TimeInterval = 0.3

    init(controller: AvatarController) {
        self.controller = controller
    }

    func setEmotion(_ emotion: Emotion, intensity: Float = 1.0, duration: TimeInterval = 0.3) {
        targetEmotion = emotion
        blendDuration = duration
        controller?.setEmotion(emotion, intensity: intensity, blendDuration: duration)
    }

    func setResting(_ emotion: Emotion) {
        currentEmotion = emotion
        if targetEmotion == .neutral {
            controller?.setEmotion(emotion, intensity: 0.5, blendDuration: 0.5)
        }
    }

    func resetToNeutral(duration: TimeInterval = 0.5) {
        targetEmotion = .neutral
        controller?.setEmotion(.neutral, intensity: 0, blendDuration: duration)
    }
}

// MARK: - GazeSystem (A3)

@MainActor
final class GazeSystem {
    private weak var controller: AvatarController?
    private var isListening = false
    private var isThinking = false
    private var gazeOverride: GazeTarget?

    init(controller: AvatarController) {
        self.controller = controller
    }

    func setListening(_ listening: Bool) {
        isListening = listening
        updateGaze()
    }

    func setThinking(_ thinking: Bool) {
        isThinking = thinking
        updateGaze()
    }

    func overrideGaze(_ target: GazeTarget?) {
        gazeOverride = target
        controller?.setGaze(target ?? .camera)
    }

    private func updateGaze() {
        if let override = gazeOverride {
            controller?.setGaze(override)
            return
        }
        if isListening {
            controller?.setGaze(.user)
        } else if isThinking {
            controller?.setGaze(.away)
        } else {
            controller?.setGaze(.camera)
        }
    }
}

// MARK: - GestureSystem (A5)

@MainActor
final class GestureSystem {
    private weak var controller: AvatarController?
    private var isGesturing = false
    private var gestureQueue: [Gesture] = []

    init(controller: AvatarController) {
        self.controller = controller
    }

    func playGesture(_ gesture: Gesture) {
        guard !isGesturing else {
            gestureQueue.append(gesture)
            return
        }
        executeGesture(gesture)
    }

    private func executeGesture(_ gesture: Gesture) {
        isGesturing = true
        controller?.playGesture(gesture)

        let duration: TimeInterval = 0.6
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.isGesturing = false
            if let next = self?.gestureQueue.first {
                self?.gestureQueue.removeFirst()
                self?.executeGesture(next)
            }
        }
    }
}

// MARK: - SecondaryMotionSystem (A6)

@MainActor
final class SecondaryMotionSystem {
    private weak var controller: AvatarController?
    private var springNodes: [(nodeName: String, stiffness: Float, damping: Float)] = []
    private var velocities: [String: SCNVector3] = [:]

    init(controller: AvatarController) {
        self.controller = controller
    }

    func registerSpring(nodeName: String, stiffness: Float = 0.5, damping: Float = 0.8) {
        springNodes.append((nodeName, stiffness, damping))
    }

    func tick(_ dt: TimeInterval, parentVelocity: SCNVector3) {
        for spring in springNodes {
            var vel = velocities[spring.nodeName] ?? SCNVector3(0, 0, 0)
            vel.x = (vel.x + parentVelocity.x * spring.stiffness) * spring.damping
            vel.y = (vel.y + parentVelocity.y * spring.stiffness) * spring.damping
            vel.z = (vel.z + parentVelocity.z * spring.stiffness) * spring.damping
            velocities[spring.nodeName] = vel
        }
    }
}

// MARK: - ReactivitySystem (A6)

@MainActor
final class ReactivitySystem {
    private weak var controller: AvatarController?
    private let emotionSystem: EmotionSystem
    private let gestureSystem: GestureSystem
    private var stage: String = "acquaintance"

    init(controller: AvatarController, emotionSystem: EmotionSystem, gestureSystem: GestureSystem) {
        self.controller = controller
        self.emotionSystem = emotionSystem
        self.gestureSystem = gestureSystem
    }

    func setStage(_ newStage: String) {
        stage = newStage
    }

    func onTap() {
        emotionSystem.setEmotion(.surprised, intensity: 0.6, duration: 0.15)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.emotionSystem.resetToNeutral(duration: 0.3)
        }
    }

    func onListeningPartial() {
        gestureSystem.playGesture(.nod)
    }

    func onReplyReceived() {
        if stage == "confidant" {
            emotionSystem.setEmotion(.affectionate, intensity: 0.4, duration: 0.3)
        }
    }
}
