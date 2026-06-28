import SceneKit
import SceneKit.ModelIO
import SwiftUI
import ModelIO
import OSLog

private let avatarLog = Logger(subsystem: "ai.companion", category: "avatar")

@MainActor
final class SceneKitAvatarController: AvatarController {
    let sceneView: SCNView
    private let scene: SCNScene
    private let rootNode: SCNNode

    // Procedural nodes
    private var headNode: SCNNode?
    private var jawNode: SCNNode?
    private var leftEyeNode: SCNNode?
    private var rightEyeNode: SCNNode?
    private var leftBrowNode: SCNNode?
    private var rightBrowNode: SCNNode?
    private var headMeshNode: SCNNode?

    // GLB nodes (loaded if present)
    private var glbRootNode: SCNNode?
    private var rigMapping: RigMapping?

    // Garment nodes
    private var garmentNodes: [WardrobeSlot: SCNNode] = [:]

    // State
    private var hasGLB = false
    private var currentEmotion: Emotion = .neutral
    private var currentEmotionIntensity: Float = 0
    private var currentGaze: GazeTarget = .camera
    private var isIdleEnabled = true
    private var appearanceColorMap: [String: UIColor] = [:]

    init() {
        scene = SCNScene()
        sceneView = SCNView(frame: .zero, options: nil)
        sceneView.scene = scene
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false

        rootNode = SCNNode()
        scene.rootNode.addChildNode(rootNode)

        setupCamera()
        buildProceduralAvatar()
    }

    func load(_ descriptor: AvatarDescriptor) async throws {
        if let glbURL = descriptor.glbURL, let mappingURL = descriptor.rigMappingURL ?? Bundle.main.url(forResource: "RigMapping", withExtension: "json") {
            do {
                let mappingData = try Data(contentsOf: mappingURL)
                rigMapping = try JSONDecoder().decode(RigMapping.self, from: mappingData)
                try loadGLB(url: glbURL)
                hasGLB = true
                avatarLog.info("Loaded GLB from \(glbURL.lastPathComponent)")
                return
            } catch {
                hasGLB = false
                avatarLog.error("GLB load failed: \(error.localizedDescription)")
            }
        }
        hasGLB = false
    }

    func applyAppearance(_ attributes: [(String, String)]) {
        for (key, value) in attributes {
            if let color = ParametricSchema.shared.color(for: key, value: value) {
                appearanceColorMap[key] = color
            }
        }
        updateAppearanceMaterials()
    }

    func attachGarment(_ garment: GarmentAsset) async throws {
        let garmentURL = Bundle.main.url(forResource: garment.glbName, withExtension: "glb")
        guard let url = garmentURL else { throw AvatarError.garmentNotFound(garment.glbName) }

        let mdlAsset = MDLAsset(url: url)
        mdlAsset.loadTextures()
        let scene = SCNScene(mdlAsset: mdlAsset)
        guard let garmentNode = scene.rootNode.childNodes.first else {
            throw AvatarError.garmentLoadFailed
        }

        garmentNode.name = "garment_\(garment.slot.rawValue)"

        if let existing = garmentNodes[garment.slot] {
            existing.removeFromParentNode()
        }
        garmentNodes[garment.slot] = garmentNode
        rootNode.addChildNode(garmentNode)

        applyBodyMask(slot: garment.slot, regions: garment.bodyMask, hidden: true)
    }

    func detachGarment(slot: WardrobeSlot) {
        garmentNodes[slot]?.removeFromParentNode()
        garmentNodes[slot] = nil
        applyBodyMask(slot: slot, regions: nil, hidden: false)
    }

    func setViseme(_ viseme: Viseme, weight: Float) {
        let visemeName: String
        if let mapping = rigMapping {
            visemeName = mapping.visemes[viseme.rawValue] ?? "viseme_\(viseme.rawValue)"
        } else {
            visemeName = "viseme_\(viseme.rawValue)"
        }

        // Procedural: jaw open for oh/aa
        if !hasGLB {
            let jawAngle: Float
            switch viseme {
            case .aa, .oh: jawAngle = weight * 0.25
            case .ee, .ih: jawAngle = weight * 0.12
            case .ou: jawAngle = weight * 0.08
            case .sil: jawAngle = 0
            }
            animateJaw(open: jawAngle)
        }

        setMorphWeight(named: visemeName, weight: weight)
    }

    func setEmotion(_ emotion: Emotion, intensity: Float, blendDuration: TimeInterval) {
        currentEmotion = emotion
        currentEmotionIntensity = intensity

        SCNTransaction.begin()
        SCNTransaction.animationDuration = blendDuration

        if hasGLB, let mapping = rigMapping, let morphs = mapping.emotions[emotion.rawValue] {
            // Use VRM blend shapes from rig mapping
            for (morphName, baseWeight) in morphs {
                setMorphWeight(named: morphName, weight: baseWeight * intensity)
            }
        } else {
            // Fall back to ARKit-style morph names
            let weights = emotion.arkitWeights()
            for (morphName, baseWeight) in weights.morphs {
                setMorphWeight(named: morphName, weight: baseWeight * intensity)
            }
        }

        if !hasGLB {
            animateBrows(for: emotion, intensity: intensity)
        }

        SCNTransaction.commit()
    }

    func playGesture(_ gesture: Gesture) {
        // Gestures require animation clips from a GLB. For procedural, do node transforms.
        guard hasGLB else {
            applyProceduralGesture(gesture)
            return
        }
        // Look up clip name from rig mapping
        guard let mapping = rigMapping, let clipName = mapping.gestures[gesture.rawValue] else { return }
        playAnimationClip(named: clipName)
    }

    func setGaze(_ target: GazeTarget) {
        currentGaze = target
        updateGaze()
    }

    func setIdle(_ enabled: Bool) {
        isIdleEnabled = enabled
    }

    func tick(_ dt: TimeInterval) {
        guard isIdleEnabled else { return }
        idleLifeTick(dt)
    }

    // MARK: - Private setup

    private func setupCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0.2, 3)
        scene.rootNode.addChildNode(cameraNode)
    }

    private func buildProceduralAvatar() {
        // Head
        let headGeo = SCNSphere(radius: 0.18)
        let headMat = SCNMaterial()
        headMat.diffuse.contents = appearanceColorMap["skin_tone"] ?? UIColor(red: 0.9, green: 0.7, blue: 0.6, alpha: 1)
        headMat.roughness.contents = 0.6
        headGeo.materials = [headMat]

        let head = SCNNode(geometry: headGeo)
        head.position = SCNVector3(0, 0, 0)
        head.name = "procedural_head"
        rootNode.addChildNode(head)
        headNode = head
        headMeshNode = head

        // Jaw (sphere below head)
        let jawGeo = SCNSphere(radius: 0.07)
        jawGeo.materials = [headMat.copy() as! SCNMaterial]
        let jaw = SCNNode(geometry: jawGeo)
        jaw.position = SCNVector3(0, -0.1, 0.12)
        jaw.name = "jaw"
        head.addChildNode(jaw)
        jawNode = jaw

        // Eyes
        let eyeGeo = SCNSphere(radius: 0.025)
        let eyeMat = SCNMaterial()
        eyeMat.diffuse.contents = UIColor.white
        eyeGeo.materials = [eyeMat]

        let leftEye = SCNNode(geometry: eyeGeo)
        leftEye.position = SCNVector3(-0.05, 0.05, 0.17)
        leftEye.name = "leftEye"
        head.addChildNode(leftEye)
        leftEyeNode = leftEye

        let rightEye = SCNNode(geometry: eyeGeo)
        rightEye.position = SCNVector3(0.05, 0.05, 0.17)
        rightEye.name = "rightEye"
        head.addChildNode(rightEye)
        rightEyeNode = rightEye

        // Pupils
        let pupilGeo = SCNSphere(radius: 0.01)
        let pupilMat = SCNMaterial()
        pupilMat.diffuse.contents = appearanceColorMap["eye_color"] ?? UIColor(red: 0.2, green: 0.3, blue: 0.6, alpha: 1)
        pupilGeo.materials = [pupilMat]

        let leftPupil = SCNNode(geometry: pupilGeo)
        leftPupil.position = SCNVector3(0, 0, 0.03)
        leftEye.addChildNode(leftPupil)

        let rightPupil = SCNNode(geometry: pupilGeo)
        rightPupil.position = SCNVector3(0, 0, 0.03)
        rightEye.addChildNode(rightPupil)

        // Brows
        let browGeo = SCNBox(width: 0.06, height: 0.01, length: 0.015, chamferRadius: 0)
        let browMat = SCNMaterial()
        browMat.diffuse.contents = UIColor(red: 0.3, green: 0.2, blue: 0.15, alpha: 1)
        browGeo.materials = [browMat]

        let leftBrow = SCNNode(geometry: browGeo)
        leftBrow.position = SCNVector3(-0.06, 0.14, 0.16)
        leftBrow.name = "leftBrow"
        head.addChildNode(leftBrow)
        leftBrowNode = leftBrow

        let rightBrow = SCNNode(geometry: browGeo)
        rightBrow.position = SCNVector3(0.06, 0.14, 0.16)
        rightBrow.name = "rightBrow"
        head.addChildNode(rightBrow)
        rightBrowNode = rightBrow
    }

    private func loadGLB(url: URL) throws {
        let mdlAsset = MDLAsset(url: url)
        mdlAsset.loadTextures()
        let glbScene = SCNScene(mdlAsset: mdlAsset)
        guard let glbRoot = glbScene.rootNode.childNodes.first else {
            avatarLog.error("MDLAsset produced no root nodes from \(url.lastPathComponent)")
            throw AvatarError.glbLoadFailed
        }
        glbRootNode = glbRoot
        rootNode.addChildNode(glbRoot)

        headNode?.isHidden = true
    }

    // MARK: - Appearance

    private func updateAppearanceMaterials() {
        if let skinColor = appearanceColorMap["skin_tone"] {
            updateProceduralSkin(color: skinColor)
        }
        if let eyeColor = appearanceColorMap["eye_color"] {
            updatePupilColor(color: eyeColor)
        }
        if let hairColor = appearanceColorMap["hair_color"] {
            updateProceduralBrow(color: hairColor)
        }
    }

    private func updateProceduralSkin(color: UIColor) {
        headMeshNode?.geometry?.materials.forEach { mat in
            mat.diffuse.contents = color
        }
        jawNode?.geometry?.materials.forEach { mat in
            mat.diffuse.contents = color
        }
    }

    private func updatePupilColor(color: UIColor) {
        leftEyeNode?.childNodes.forEach { node in
            node.geometry?.materials.forEach { $0.diffuse.contents = color }
        }
        rightEyeNode?.childNodes.forEach { node in
            node.geometry?.materials.forEach { $0.diffuse.contents = color }
        }
    }

    private func updateProceduralBrow(color: UIColor) {
        leftBrowNode?.geometry?.materials.forEach { $0.diffuse.contents = color }
        rightBrowNode?.geometry?.materials.forEach { $0.diffuse.contents = color }
    }

    // MARK: - Morph targets

    func setMorphWeight(named name: String, weight: Float) {
        let searchNodes = hasGLB ? [glbRootNode].compactMap { $0 } : [headNode].compactMap { $0 }
        for node in searchNodes {
            walkNodeTree(node) { n in
                guard let morpher = n.morpher else { return }
                for (i, target) in morpher.targets.enumerated() {
                    if target.name == name || target.name?.contains(name) == true {
                        morpher.setWeight(CGFloat(weight), forTargetAt: i)
                    }
                }
            }
        }
    }

    private func walkNodeTree(_ node: SCNNode, visit: (SCNNode) -> Void) {
        visit(node)
        for child in node.childNodes {
            walkNodeTree(child, visit: visit)
        }
    }

    // MARK: - Procedural animation

    private func animateJaw(open: Float) {
        jawNode?.position = SCNVector3(0, -0.1 - open * 0.03, 0.12)
        let angle = open * 0.3
        jawNode?.eulerAngles = SCNVector3(angle, 0, 0)
    }

    private func animateBrows(for emotion: Emotion, intensity: Float) {
        let browUp: Float
        let browAngle: Float
        switch emotion {
        case .surprised, .warm, .happy: browUp = 0.06 * intensity; browAngle = -0.1 * intensity
        case .sad, .concerned: browUp = 0.03 * intensity; browAngle = 0.05 * intensity
        case .thoughtful: browUp = -0.02 * intensity; browAngle = 0.08 * intensity
        default: browUp = 0; browAngle = 0
        }

        leftBrowNode?.position = SCNVector3(-0.06, 0.14 + browUp, 0.16)
        rightBrowNode?.position = SCNVector3(0.06, 0.14 + browUp, 0.16)
        leftBrowNode?.eulerAngles = SCNVector3(0, 0, browAngle)
        rightBrowNode?.eulerAngles = SCNVector3(0, 0, -browAngle)
    }

    private func applyProceduralGesture(_ gesture: Gesture) {
        guard let head = headNode else { return }
        switch gesture {
        case .nod:
            let up = SCNAction.rotateTo(x: 0.1, y: 0, z: 0, duration: 0.15)
            let down = SCNAction.rotateTo(x: -0.05, y: 0, z: 0, duration: 0.15)
            let neutral = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.15)
            head.runAction(SCNAction.sequence([up, down, neutral]))
        case .shakeHead:
            let right = SCNAction.rotateTo(x: 0, y: 0.15, z: 0, duration: 0.15)
            let left = SCNAction.rotateTo(x: 0, y: -0.1, z: 0, duration: 0.15)
            let neutral = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.15)
            head.runAction(SCNAction.sequence([right, left, neutral]))
        case .tiltHead:
            head.runAction(SCNAction.sequence([
                SCNAction.rotateTo(x: 0, y: 0, z: 0.15, duration: 0.2),
                SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.3)
            ]))
        case .leanIn:
            let forward = SCNAction.move(to: SCNVector3(0, 0, 0.15), duration: 0.2)
            let back = SCNAction.move(to: SCNVector3(0, 0, 0), duration: 0.3)
            head.runAction(SCNAction.sequence([forward, back]))
        case .laugh:
            let up = SCNAction.rotateTo(x: 0.05, y: 0, z: 0, duration: 0.12)
            let down = SCNAction.rotateTo(x: -0.03, y: 0, z: 0, duration: 0.12)
            let neutral = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.25)
            head.runAction(SCNAction.sequence([up, down, neutral]))
        default: break
        }
    }

    private func playAnimationClip(named name: String) {
        // Animation clip playback requires SCNAnimationPlayer from the GLB scene
    }

    // MARK: - Gaze

    private func updateGaze() {
        let targetPos: SCNVector3
        switch currentGaze {
        case .camera: targetPos = SCNVector3(0, 0, 10)
        case .user: targetPos = SCNVector3(0, 0, 3)
        case .away: targetPos = SCNVector3(0.5, 0, 5)
        case .idle: targetPos = SCNVector3(0, 0, 10)
        }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.2
        leftEyeNode?.look(at: targetPos)
        rightEyeNode?.look(at: targetPos)
        SCNTransaction.commit()
    }

    // MARK: - Idle life (A1)

    private var lastBlink: TimeInterval = 0
    private var nextBlinkInterval: TimeInterval = 3
    private var blinkPhase: Float = 0
    private var breathePhase: Float = 0
    private var swayPhase: Float = 0
    private var lastSaccadeTime: TimeInterval = 0
    private var nextSaccadeInterval: TimeInterval = 2

    private func idleLifeTick(_ dt: TimeInterval) {
        let now = CACurrentMediaTime()

        // Blink
        if now - lastBlink > nextBlinkInterval {
            performBlink()
            lastBlink = now
            nextBlinkInterval = TimeInterval(2 + Float.random(in: 0...4))
        }

        // Breathe
        breathePhase += Float(dt) * 2.5
        let breathe = sin(breathePhase) * 0.005
        headNode?.position.y = breathe

        // Sway
        swayPhase += Float(dt) * 0.6
        let sway = sin(swayPhase) * 0.003
        headNode?.eulerAngles.z = sway

        // Micro-saccades
        if now - lastSaccadeTime > nextSaccadeInterval {
            let saccadeX = Float.random(in: -0.005...0.005)
            let saccadeY = Float.random(in: -0.005...0.005)
            leftEyeNode?.position.x = -0.05 + saccadeX
            leftEyeNode?.position.y = 0.05 + saccadeY
            rightEyeNode?.position.x = 0.05 + saccadeX
            rightEyeNode?.position.y = 0.05 + saccadeY
            lastSaccadeTime = now
            nextSaccadeInterval = TimeInterval.random(in: 1...4)
        }
    }

    private func performBlink() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.05
        leftEyeNode?.scale = SCNVector3(1, 0.05, 1)
        rightEyeNode?.scale = SCNVector3(1, 0.05, 1)
        SCNTransaction.commit()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.05
            self?.leftEyeNode?.scale = SCNVector3(1, 1, 1)
            self?.rightEyeNode?.scale = SCNVector3(1, 1, 1)
            SCNTransaction.commit()
        }
    }

    // MARK: - Body mask for garments

    private func applyBodyMask(slot: WardrobeSlot, regions: Set<String>?, hidden: Bool) {
        // Hide base body mesh regions to prevent poke-through
        guard let head = headMeshNode else { return }
        head.isHidden = hidden && slot == .headwear
    }
}

enum AvatarError: Error {
    case garmentNotFound(String)
    case garmentLoadFailed
    case glbLoadFailed
}
