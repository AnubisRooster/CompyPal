import SceneKit
import SwiftUI
import OSLog
import GLTFKit2

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
    var isGLBLoaded: Bool { hasGLB }
    private var currentEmotion: Emotion = .neutral
    private var currentEmotionIntensity: Float = 0
    private var currentGaze: GazeTarget = .camera
    private var isIdleEnabled = true
    private var reduceMotion = false

    // GLB skeleton driving (idle pose, gaze, gestures). VRM/VRoid humanoids ship in a
    // static T-pose with no animation clips, so all body/head motion is generated here
    // by offsetting skeleton bones from their captured rest transforms each frame.
    private struct GLBBone {
        let node: SCNNode
        let restEuler: SCNVector3
        let restPosition: SCNVector3
    }
    private var glbBones: [String: GLBBone] = [:]
    // Rest transform of the whole model, for whole-body moves (twirl/spin/jump).
    private var glbRootRestEuler = SCNVector3Zero
    private var glbRootRestPosition = SCNVector3Zero

    // Smoothed gaze (radians), driven toward target each frame.
    private var gazeYaw: Float = 0
    private var gazePitch: Float = 0
    private var targetGazeYaw: Float = 0
    private var targetGazePitch: Float = 0

    // A transient, time-based gesture composited additively on top of idle + gaze.
    private struct ActiveGesture {
        let gesture: Gesture
        let start: TimeInterval
        let duration: TimeInterval
    }
    private var activeGesture: ActiveGesture?

    // Real animation clips discovered in the GLB (and any sidecar `anim_*.glb` files that
    // share the VRM skeleton). VRoid exports ship none, so this is usually empty and
    // gestures fall back to the procedural system; when a matching clip exists it is
    // preferred for higher-fidelity motion and drives the skeleton directly.
    private var clipPlayers: [String: SCNAnimationPlayer] = [:]
    private var isClipPlaying = false
    private var clipEndWork: DispatchWorkItem?
    var availableClipNames: [String] { clipPlayers.keys.sorted() }

    private var appearanceColorMap: [String: UIColor] = [:]
    private var morpherIndex: [String: [(morpher: SCNMorpher, targetIndex: Int)]] = [:]
    var morpherIndexCount: Int { morpherIndex.values.reduce(0) { $0 + $1.count } }
    var morpherIndexUniqueNameCount: Int { morpherIndex.count }

#if DEBUG
    func morpherIndexContains(_ name: String) -> Bool { morpherIndex[name] != nil }
    func morpherEntriesCount(for name: String) -> Int { morpherIndex[name]?.count ?? 0 }
#endif

    init() {
        scene = SCNScene()
        sceneView = SCNView(frame: .zero, options: nil)
        sceneView.scene = scene
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false
        // Keep rendering so the loaded model, idle motion, and lip sync stay live.
        sceneView.rendersContinuously = true

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

    func applyReferenceImage(_ image: UIImage) {
        if hasGLB, let root = glbRootNode {
            var applied = false
            root.enumerateChildNodes { node, stop in
                guard let name = node.name?.lowercased() else { return }
                let isFace = name.contains("face") || name.contains("head") || name.contains("skin")
                guard isFace else { return }
                guard let geo = node.geometry, geo.materials.contains(where: { $0.diffuse.contents is UIImage }) else { return }
                geo.materials.forEach { $0.diffuse.contents = image; $0.roughness.contents = 0.8 }
                applied = true
                stop.pointee = ObjCBool(true)
            }
            if !applied {
                root.enumerateChildNodes { node, stop in
                    guard let geo = node.geometry else { return }
                    geo.materials.forEach { $0.diffuse.contents = image; $0.roughness.contents = 0.8 }
                    applied = true
                    stop.pointee = ObjCBool(true)
                }
            }
        } else {
            let head = scene.rootNode.childNode(withName: "procedural_head", recursively: true)
            head?.geometry?.materials.forEach { $0.diffuse.contents = image; $0.roughness.contents = 0.8 }
        }
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

        let gltfAsset = try GLTFAsset(url: url, options: [:])
        let source = GLTFSCNSceneSource(asset: gltfAsset)
        guard let scene = source.defaultScene else {
            throw AvatarError.garmentLoadFailed
        }
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
            setMorphWeight(named: visemeName, weight: weight)
            return
        }

        // GLB: don't write the morph directly. Stash the target so updateGLBFace can ease
        // toward it and, critically, release every *other* mouth viseme — otherwise each
        // frame's shape stacks on the last and the mouth turns into a garbled blend.
        if glbVisemeMorphNames.isEmpty, let m = rigMapping {
            glbVisemeMorphNames = Array(Set(m.visemes.values))
        }
        glbVisemeTarget = (viseme == .sil || weight < 0.04) ? nil : (visemeName, min(weight, 1))
    }

    func setEmotion(_ emotion: Emotion, intensity: Float, blendDuration: TimeInterval) {
        currentEmotion = emotion
        currentEmotionIntensity = intensity

        if hasGLB {
            // Store the desired expression; updateGLBFace eases the VRM blend shapes
            // toward it every frame so transitions are smooth and the face stays held
            // (rather than snapping once via a one-shot animation).
            var target: [String: Float] = [:]
            if let mapping = rigMapping, let morphs = mapping.emotions[emotion.rawValue] {
                for (morphName, baseWeight) in morphs {
                    // Skip "Neutral" preset morphs: the base mesh is already a neutral
                    // face, so additively driving Fcl_ALL_Neutral / Fcl_MTH_Neutral puffs
                    // the lips and cheeks ("puffer fish"). Neutral = no morphs.
                    if morphName.range(of: "Neutral", options: .caseInsensitive) != nil { continue }
                    target[morphName] = baseWeight * intensity
                }
            }
            targetEmotionMorphs = target
            return
        }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = blendDuration
        let weights = emotion.arkitWeights()
        for (morphName, baseWeight) in weights.morphs {
            setMorphWeight(named: morphName, weight: baseWeight * intensity)
        }
        animateBrows(for: emotion, intensity: intensity)
        SCNTransaction.commit()
    }

    func playGesture(_ gesture: Gesture) {
        if hasGLB {
            // Prefer a real animation clip when one is available for this gesture; it
            // drives the skeleton directly for higher fidelity than procedural offsets.
            if let clipKey = resolveClipKey(for: gesture) {
                playClip(key: clipKey)
                return
            }
            // Otherwise gestures are generated as additive, time-based bone offsets in
            // the skeleton update (VRoid exports ship no clips).
            let duration: TimeInterval
            switch gesture {
            case .dance: duration = 3.2
            case .stretch: duration = 1.6
            case .twirl: duration = 1.6
            case .wave: duration = 1.7
            case .spin: duration = 1.4
            case .point: duration = 1.4
            case .bow: duration = 1.3
            case .handToChest: duration = 1.1
            case .jump: duration = 1.1
            case .shrug: duration = 0.9
            case .shakeHead: duration = 0.9
            case .nod, .laugh: duration = 0.7
            default: duration = 0.6
            }
            activeGesture = ActiveGesture(gesture: gesture, start: CACurrentMediaTime(), duration: duration)
            return
        }
        applyProceduralGesture(gesture)
    }

    func setGaze(_ target: GazeTarget) {
        currentGaze = target
        if hasGLB {
            setGLBGazeTarget(target)
        } else {
            updateGaze()
        }
    }

    func setIdle(_ enabled: Bool) {
        isIdleEnabled = enabled
    }

    /// Suspends all generated motion (Reduce Motion accessibility setting).
    func setReduceMotion(_ enabled: Bool) {
        reduceMotion = enabled
        if enabled, hasGLB {
            // Snap back to the static rest pose.
            for (_, bone) in glbBones {
                bone.node.eulerAngles = bone.restEuler
                bone.node.position = bone.restPosition
            }
            activeGesture = nil
            glbExprFlicker = nil
            clipEndWork?.cancel()
            isClipPlaying = false
            clipPlayers.values.forEach { $0.stop() }
            for key in currentEmotionMorphs.keys { setMorphWeight(named: key, weight: 0) }
            currentEmotionMorphs.removeAll()
            for key in glbCurrentVisemeWeights.keys { setMorphWeight(named: key, weight: 0) }
            glbCurrentVisemeWeights.removeAll()
            glbVisemeTarget = nil
            glbRootNode?.eulerAngles = glbRootRestEuler
            glbRootNode?.position = glbRootRestPosition
        }
    }

    func tick(_ dt: TimeInterval) {
        if hasGLB {
            updateGLBSkeleton(dt)
            return
        }
        guard isIdleEnabled else { return }
        idleLifeTick(dt)
    }

    // MARK: - Private setup

    private func setupCamera() {
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        // The avatar viewport is wide and short. Lock the field of view to the
        // vertical axis so a tall humanoid is framed by height (not width), otherwise
        // the default horizontal FOV crops the model down to a torso close-up.
        camera.fieldOfView = 55
        camera.projectionDirection = .vertical
        camera.zNear = 0.01
        cameraNode.camera = camera
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
        let gltfAsset = try GLTFAsset(url: url, options: [:])
        let source = GLTFSCNSceneSource(asset: gltfAsset)
        guard let glbScene = source.defaultScene else { throw AvatarError.glbLoadFailed }
        let children = glbScene.rootNode.childNodes
        guard !children.isEmpty else {
            avatarLog.error("GLTFKit2 produced no root nodes from \(url.lastPathComponent)")
            throw AvatarError.glbLoadFailed
        }
        // GLTFKit2 may put content as direct children of the scene root,
        // or nest everything under a single container node. Handle both:
        // if there's exactly one child, use it as the root; otherwise
        // create a container to hold all children.
        if children.count == 1, let single = children.first {
            glbRootNode = single
            rootNode.addChildNode(single)
        } else {
            let container = SCNNode()
            container.name = "glb_container"
            for child in Array(children) { container.addChildNode(child) }
            glbRootNode = container
            rootNode.addChildNode(container)
        }

        if let glbRootNode {
            // Hide stray environment/helper meshes (e.g. Blender's default "Cube",
            // exported into riven.glb) that otherwise render as a large gray block and
            // dominate the framing bounding box.
            glbRootNode.enumerateHierarchy { node, _ in
                if let name = node.name, name.lowercased().hasPrefix("cube") {
                    node.isHidden = true
                }
            }
            frameModel(glbRootNode)
        }
        headNode?.isHidden = true
        buildMorpherIndex()
        recoverMorphTargetNames(from: url)
        resolveGLBBones()
        applyRestPose()
        loadAnimationClips(from: source, glbURL: url)

        // Greet with a wave shortly after appearing.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.playGesture(.wave)
        }
    }

    // MARK: - GLB skeleton resolution & posing

    /// Caches the humanoid bones we animate, recording each bone's rest (bind-pose)
    /// transform so per-frame motion can be expressed as offsets from rest.
    private func resolveGLBBones() {
        glbBones.removeAll()
        guard let root = glbRootNode else { return }

        func add(_ logical: String, _ boneName: String?) {
            guard let boneName, !boneName.isEmpty,
                  let node = root.childNode(withName: boneName, recursively: true) else { return }
            glbBones[logical] = GLBBone(node: node, restEuler: node.eulerAngles, restPosition: node.position)
        }

        let sk = rigMapping?.skeleton ?? [:]
        add("head", sk["head"])
        add("neck", sk["neck"])
        add("upperChest", sk["upperChest"])
        add("chest", sk["chest"])
        add("spine", sk["spine"])
        add("hips", sk["hips"])
        add("leftEye", sk["leftEye"])
        add("rightEye", sk["rightEye"])

        // Arm bones aren't in the rig mapping; use the VRM/VRoid standard names.
        add("leftUpperArm", "J_Bip_L_UpperArm")
        add("rightUpperArm", "J_Bip_R_UpperArm")
        add("leftLowerArm", "J_Bip_L_LowerArm")
        add("rightLowerArm", "J_Bip_R_LowerArm")
        add("leftHand", "J_Bip_L_Hand")
        add("rightHand", "J_Bip_R_Hand")
        add("leftUpperLeg", "J_Bip_L_UpperLeg")
        add("rightUpperLeg", "J_Bip_R_UpperLeg")
        add("leftLowerLeg", "J_Bip_L_LowerLeg")
        add("rightLowerLeg", "J_Bip_R_LowerLeg")

        if let root = glbRootNode {
            glbRootRestEuler = root.eulerAngles
            glbRootRestPosition = root.position
        }

        avatarLog.info("Resolved GLB bones: \(self.glbBones.keys.sorted().joined(separator: ", "))")
    }

    /// Replaces the imported T-pose with a relaxed standing pose by lowering the upper
    /// arms to the sides and adding a slight elbow bend, then re-captures those bones'
    /// rest transforms so gesture offsets compose from the relaxed pose.
    private func applyRestPose() {
        func pose(_ logical: String, _ delta: SCNVector3) {
            guard let bone = glbBones[logical] else { return }
            let posed = SCNVector3(bone.restEuler.x + delta.x,
                                   bone.restEuler.y + delta.y,
                                   bone.restEuler.z + delta.z)
            bone.node.eulerAngles = posed
            glbBones[logical] = GLBBone(node: bone.node, restEuler: posed, restPosition: bone.restPosition)
        }

        // Lower the upper arms ~70° toward the body. Signs are mirrored per side and
        // tuned for the VRoid bone axes (rotation about Z drops the arm).
        let armDrop: Float = 1.22
        pose("leftUpperArm", SCNVector3(0, 0, -armDrop))
        pose("rightUpperArm", SCNVector3(0, 0, armDrop))
        // Small natural elbow bend.
        pose("leftLowerArm", SCNVector3(0, -0.15, -0.12))
        pose("rightLowerArm", SCNVector3(0, 0.15, 0.12))
    }

    /// Centers and uniformly scales a freshly-loaded GLB so it fits the fixed camera.
    /// Imported VRM/glTF humanoids are full-scale (≈1.5m) and arrive with their feet
    /// near the origin, which leaves them almost entirely out of the procedural-tuned
    /// camera frame — the cause of an apparently empty avatar view.
    private func frameModel(_ node: SCNNode) {
        guard let (minV, maxV) = hierarchyBoundingBox(of: node) else { return }
        let dx = maxV.x - minV.x
        let dy = maxV.y - minV.y
        let dz = maxV.z - minV.z
        let maxDim = max(dx, max(dy, dz))
        guard maxDim.isFinite, maxDim > 0 else { return }

        _ = maxDim
        guard dy > 0 else { return }

        // Frame the full body: scale by the model's height so head-to-feet fits the
        // camera's vertical field of view, center the model, and lift it so its center
        // aligns with the camera's eye line for a balanced full-body shot.
        let targetHeight: Float = 2.7
        let scale = targetHeight / dy
        let centerX = (minV.x + maxV.x) / 2
        let centerY = (minV.y + maxV.y) / 2
        let centerZ = (minV.z + maxV.z) / 2
        node.pivot = SCNMatrix4MakeTranslation(centerX, centerY, centerZ)
        node.scale = SCNVector3(scale, scale, scale)
        node.position = SCNVector3(0, 0.2, 0)
        avatarLog.info("Framed GLB: rawMaxDim=\(maxDim), height=\(dy), scale=\(scale)")
    }

    /// Robust bounding box over a node's full subtree, in `root`'s coordinate space.
    /// Unlike `flattenedClone().boundingBox`, this correctly bounds skinned meshes by
    /// converting each geometry node's local bounds into the root's space.
    private func hierarchyBoundingBox(of root: SCNNode) -> (min: SCNVector3, max: SCNVector3)? {
        var minV = SCNVector3(Float.greatestFiniteMagnitude, .greatestFiniteMagnitude, .greatestFiniteMagnitude)
        var maxV = SCNVector3(-Float.greatestFiniteMagnitude, -.greatestFiniteMagnitude, -.greatestFiniteMagnitude)
        var found = false
        root.enumerateHierarchy { node, _ in
            guard node.geometry != nil, !node.isHidden else { return }
            let (lmin, lmax) = node.boundingBox
            guard lmax.x >= lmin.x else { return }
            let corners = [
                SCNVector3(lmin.x, lmin.y, lmin.z), SCNVector3(lmax.x, lmin.y, lmin.z),
                SCNVector3(lmin.x, lmax.y, lmin.z), SCNVector3(lmin.x, lmin.y, lmax.z),
                SCNVector3(lmax.x, lmax.y, lmin.z), SCNVector3(lmax.x, lmin.y, lmax.z),
                SCNVector3(lmin.x, lmax.y, lmax.z), SCNVector3(lmax.x, lmax.y, lmax.z),
            ]
            for corner in corners {
                let p = root.convertPosition(corner, from: node)
                minV.x = Swift.min(minV.x, p.x); minV.y = Swift.min(minV.y, p.y); minV.z = Swift.min(minV.z, p.z)
                maxV.x = Swift.max(maxV.x, p.x); maxV.y = Swift.max(maxV.y, p.y); maxV.z = Swift.max(maxV.z, p.z)
                found = true
            }
        }
        return found ? (minV, maxV) : nil
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
        if hasGLB, let entries = morpherIndex[name], !entries.isEmpty {
            for entry in entries {
                entry.morpher.setWeight(CGFloat(weight), forTargetAt: entry.targetIndex)
            }
            return
        }
        for node in [headNode].compactMap({ $0 }) {
            guard let morpher = node.morpher else { continue }
            for (i, target) in morpher.targets.enumerated() {
                if target.name == name || target.name?.contains(name) == true {
                    morpher.setWeight(CGFloat(weight), forTargetAt: i)
                }
            }
        }
    }

    private func buildMorpherIndex() {
        morpherIndex.removeAll(keepingCapacity: true)
        guard let root = glbRootNode else { return }
        var seen: Set<String> = []
        root.enumerateChildNodes { node, _ in
            guard let morpher = node.morpher else { return }
            for (i, target) in morpher.targets.enumerated() {
                let key = target.name ?? "target_\(i)"
                let dedupKey = "\(Unmanaged.passUnretained(morpher).toOpaque()):\(i)"
                guard seen.insert(dedupKey).inserted else { continue }
                morpherIndex[key, default: []].append((morpher, i))
                if let altName = rigMapping?.visemes.first(where: { $0.value == key })?.key {
                    morpherIndex[altName, default: []].append((morpher, i))
                }
            }
        }
    }

    /// GLTFKit2 may strip morph target names from glTF assets.
    /// Fall back to parsing the GLB JSON chunk to recover names from any of the
    /// three locations the glTF 2.0 spec permits.
    private func recoverMorphTargetNames(from glbURL: URL) {
        guard morpherIndex.keys.contains(where: { $0.hasPrefix("target_") }) else {
            avatarLog.info("Morph target names already present, no recovery needed")
            return
        }
        guard let data = try? Data(contentsOf: glbURL) else {
            avatarLog.error("Could not read GLB for name recovery")
            return
        }

        // GLB layout: magic(4) + version(4) + length(4) = 12 bytes header
        // Then chunks: chunkLength(4) + chunkType(4) + chunkData(chunkLength)
        var offset = 12
        var jsonData: Data?
        while offset + 8 <= data.count {
            let chunkLength = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self) }
            let chunkType = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset + 4, as: UInt32.self) }
            offset += 8
            if chunkType == 0x4E4F534A {
                jsonData = data.subdata(in: offset..<offset + Int(chunkLength))
                break
            }
            offset += Int(chunkLength)
        }
        guard let jsonData,
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let meshes = json["meshes"] as? [[String: Any]]
        else {
            avatarLog.error("Could not parse GLB JSON chunk for name recovery")
            return
        }

        // Collect target names from each mesh, checking all three spec-permitted locations:
        //   1) meshes[i].extras.targetNames                  (most common — Blender, VRoidStudio, three.js)
        //   2) meshes[i].primitives[j].extras.targetNames    (some older exporters)
        //   3) meshes[i].primitives[j].targets[k].extras.targetNames  (rare)
        var meshNamesList: [[String]] = []
        for mesh in meshes {
            var names: [String] = []
            if let extras = mesh["extras"] as? [String: Any],
               let mn = extras["targetNames"] as? [String] {
                names = mn
            }
            if names.isEmpty, let primitives = mesh["primitives"] as? [[String: Any]] {
                for primitive in primitives {
                    if let extras = primitive["extras"] as? [String: Any],
                       let pn = extras["targetNames"] as? [String] {
                        names = pn
                        break
                    }
                    if let targets = primitive["targets"] as? [[String: Any]] {
                        var perTarget: [String] = []
                        for target in targets {
                            if let extras = target["extras"] as? [String: Any],
                               let tn = extras["targetNames"] as? [String],
                               let first = tn.first {
                                perTarget.append(first)
                            }
                        }
                        if !perTarget.isEmpty { names = perTarget; break }
                    }
                }
            }
            meshNamesList.append(names)
        }

        // Walk SceneKit morphers, grouped by parent node.
        // GLTFKit2 creates one SCNMorpher per primitive; all primitives of a glTF mesh
        // share the same morph target structure (glTF 2.0 requirement §5.3.4).
        // Group by parent so one mesh's names pair with all its primitives' morphers.
        guard let root = glbRootNode else { return }
        var morphersByParent: [(parent: SCNNode?, morphers: [SCNMorpher])] = []
        root.enumerateChildNodes { node, _ in
            guard let morpher = node.morpher else { return }
            let parent = node.parent
            if let last = morphersByParent.last, last.parent === parent {
                morphersByParent[morphersByParent.count - 1].morphers.append(morpher)
            } else {
                morphersByParent.append((parent, [morpher]))
            }
        }

        var meshIdx = 0
        var rebuilt: [String: [(morpher: SCNMorpher, targetIndex: Int)]] = [:]
        var rebuiltSeen: Set<String> = []
        var recoveredCount = 0
        for group in morphersByParent {
            while meshIdx < meshNamesList.count, meshNamesList[meshIdx].isEmpty {
                meshIdx += 1
            }
            guard meshIdx < meshNamesList.count else { break }
            let names = meshNamesList[meshIdx]
            meshIdx += 1

            for morpher in group.morphers {
                for (i, target) in morpher.targets.enumerated() {
                    guard i < names.count else { break }
                    let dedupKey = "\(Unmanaged.passUnretained(morpher).toOpaque()):\(i)"
                    guard rebuiltSeen.insert(dedupKey).inserted else { continue }
                    let realName = names[i]
                    rebuilt[realName, default: []].append((morpher, i))
                    recoveredCount += 1

                    if let mapping = rigMapping {
                        for (vocab, mapped) in mapping.visemes where mapped == realName {
                            rebuilt[vocab, default: []].append((morpher, i))
                        }
                        if mapping.blink.left == realName { rebuilt["blink_left", default: []].append((morpher, i)) }
                        if mapping.blink.right == realName { rebuilt["blink_right", default: []].append((morpher, i)) }
                    }

                    if let existingName = target.name, existingName != realName {
                        rebuilt[existingName, default: []].append((morpher, i))
                    }
                }
            }
        }

        if recoveredCount > 0 {
            for (key, entries) in morpherIndex where !key.hasPrefix("target_") {
                if rebuilt[key] == nil { rebuilt[key] = entries }
            }
            morpherIndex = rebuilt
            avatarLog.info("Recovered \(recoveredCount) morph target bindings; unique names: \(self.morpherIndexUniqueNameCount), total: \(self.morpherIndexCount)")
        } else {
            avatarLog.warning("No morph target names found in GLB JSON at any of the three spec-permitted locations")
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

    // MARK: - Animation clips

    /// Collects animation clips from the avatar GLB and any sidecar `anim_*.glb` files in
    /// the bundle, keying each `SCNAnimationPlayer` by a lowercased name. Clips that share
    /// the VRM skeleton (same bone names) animate the loaded character directly.
    private func loadAnimationClips(from source: GLTFSCNSceneSource, glbURL: URL) {
        clipPlayers.removeAll()
        registerClips(source.animations)

        let sidecars = (Bundle.main.urls(forResourcesWithExtension: "glb", subdirectory: nil) ?? [])
            .filter { $0.lastPathComponent.lowercased().hasPrefix("anim_") }
        for fileURL in sidecars {
            guard let asset = try? GLTFAsset(url: fileURL, options: [:]) else { continue }
            let base = fileURL.deletingPathExtension().lastPathComponent
                .replacingOccurrences(of: "anim_", with: "", options: [.caseInsensitive, .anchored])
            registerClips(GLTFSCNSceneSource(asset: asset).animations, fallbackName: base)
        }

        if clipPlayers.isEmpty {
            avatarLog.info("No animation clips found; gestures use procedural motion.")
        } else {
            avatarLog.info("Loaded animation clips: \(self.availableClipNames.joined(separator: ", "))")
        }
    }

    private func registerClips(_ anims: [GLTFSCNAnimation], fallbackName: String? = nil) {
        guard let root = glbRootNode else { return }
        for (i, anim) in anims.enumerated() {
            let rawName = anim.name.isEmpty ? (fallbackName ?? "clip_\(i)") : anim.name
            let key = rawName.lowercased()
            let player = anim.animationPlayer
            player.stop()
            player.animation.repeatCount = 1
            player.animation.isRemovedOnCompletion = false
            root.addAnimationPlayer(player, forKey: key)
            clipPlayers[key] = player
        }
    }

    /// Returns the clip key to play for a gesture, preferring an explicit RigMapping
    /// `gestures` entry and falling back to a clip named after the gesture itself.
    private func resolveClipKey(for gesture: Gesture) -> String? {
        if let mapped = rigMapping?.gestures[gesture.rawValue]?.lowercased(), clipPlayers[mapped] != nil {
            return mapped
        }
        let raw = gesture.rawValue.lowercased()
        return clipPlayers[raw] != nil ? raw : nil
    }

    private func playClip(key: String) {
        guard let player = clipPlayers[key] else { return }
        clipEndWork?.cancel()
        activeGesture = nil
        restoreRestPose()
        isClipPlaying = true
        player.stop()
        player.play()

        let duration = player.animation.duration > 0 ? player.animation.duration : 1.0
        let work = DispatchWorkItem { [weak self] in
            self?.isClipPlaying = false
            self?.restoreRestPose()
        }
        clipEndWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }

    /// Snaps every tracked bone and the root back to their captured rest transforms so
    /// procedural motion resumes cleanly after a clip (or is reset on Reduce Motion).
    private func restoreRestPose() {
        for (_, bone) in glbBones {
            bone.node.eulerAngles = bone.restEuler
            bone.node.position = bone.restPosition
        }
        glbRootNode?.eulerAngles = glbRootRestEuler
        glbRootNode?.position = glbRootRestPosition
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

    // MARK: - GLB skeleton life (idle pose, breathing, gaze, gestures, blink)

    private var glbBreathePhase: Float = 0
    private var glbSwayPhase: Float = 0
    private var glbLastBlink: TimeInterval = 0
    private var glbNextBlinkInterval: TimeInterval = 3
    private var glbLastIdleGesture: TimeInterval = 0
    private var glbNextIdleGestureInterval: TimeInterval = 8

    // Idle gaze drift, so her eyes aren't locked dead-ahead while resting.
    private var glbLastGazeDrift: TimeInterval = 0
    private var glbNextGazeDrift: TimeInterval = 3
    private var glbGazeDriftYaw: Float = 0
    private var glbGazeDriftPitch: Float = 0

    // Living face: the held emotion is eased toward its target every frame, with a slow
    // ambient brow motion and occasional spontaneous flickers layered on top so a resting
    // face never looks frozen.
    private var targetEmotionMorphs: [String: Float] = [:]
    private var currentEmotionMorphs: [String: Float] = [:]
        private var glbFaceBrowPhase: Float = 0
        // Lip-sync: a single mouth channel. The energy sampler sets the active viseme each
        // frame; updateGLBFace eases toward it and zeroes the rest so shapes never stack.
        private var glbVisemeMorphNames: [String] = []
        private var glbVisemeTarget: (name: String, weight: Float)?
        private var glbCurrentVisemeWeights: [String: Float] = [:]
    private var glbLastExprFlicker: TimeInterval = 0
    private var glbNextExprFlickerInterval: TimeInterval = 5
    private struct ExprFlicker { let start: TimeInterval; let dur: TimeInterval; let morphs: [String: Float] }
    private var glbExprFlicker: ExprFlicker?

    /// Master per-frame update for the GLB humanoid. Composes three additive layers on
    /// top of each bone's rest transform: ambient idle motion (breathing/sway/weight
    /// shift), smoothed gaze, and a transient gesture. Breathing and blinking continue
    /// even while "idle" is suspended (e.g. during speech) so she never looks frozen;
    /// the larger idle sway is gated by `isIdleEnabled`.
    private func updateGLBSkeleton(_ dt: TimeInterval) {
        guard hasGLB, !reduceMotion else { return }
        let now = CACurrentMediaTime()

        // While a real animation clip is playing it owns the skeleton; only keep the
        // face and blinking alive so procedural bone writes don't fight the clip.
        if isClipPlaying {
            updateGLBFace(dt, now: now)
            updateGLBBlink(now: now)
            return
        }

        let idleAmp: Float = isIdleEnabled ? 1 : 0

        glbBreathePhase += Float(dt) * 1.5
        glbSwayPhase += Float(dt) * 0.55
        let breathe = sin(glbBreathePhase)
        let sway = sin(glbSwayPhase)

        // Idle gaze drift: occasionally glance around so the eyes aren't locked forward.
        if idleAmp > 0 {
            if now - glbLastGazeDrift > glbNextGazeDrift {
                glbGazeDriftYaw = Float.random(in: -0.1...0.1)
                glbGazeDriftPitch = Float.random(in: -0.05...0.05)
                glbLastGazeDrift = now
                glbNextGazeDrift = TimeInterval.random(in: 2.5...5)
            }
        } else {
            glbGazeDriftYaw = 0
            glbGazeDriftPitch = 0
        }

        // Smoothly approach the current gaze target (plus any idle drift).
        let lerp = min(Float(dt) * 6, 1)
        gazeYaw += (targetGazeYaw + glbGazeDriftYaw - gazeYaw) * lerp
        gazePitch += (targetGazePitch + glbGazeDriftPitch - gazePitch) * lerp

        // Occasionally play a small idle gesture so resting isn't perfectly static.
        // The pool and cadence are tinted by the current emotion so a happy Riven
        // fidgets more brightly and a thoughtful one settles down.
        if idleAmp > 0, activeGesture == nil, now - glbLastIdleGesture > glbNextIdleGestureInterval {
            let pool = idleGesturePool(for: currentEmotion)
            activeGesture = ActiveGesture(gesture: pool.randomElement() ?? .tiltHead,
                                          start: now, duration: 0.8)
            glbLastIdleGesture = now
            glbNextIdleGestureInterval = idleGestureInterval(for: currentEmotion)
        }

        // Evaluate the transient gesture into additive deltas: head/spine bones, arm
        // bones, and a whole-body root transform (yaw/lift). Whole-body moves rotate or
        // lift the entire rigged model, which reads cleanly without per-joint tuning.
        var gHeadPitch: Float = 0, gHeadYaw: Float = 0, gHeadRoll: Float = 0, gSpinePitch: Float = 0
        var gChestPitch: Float = 0
        var armDeltas: [String: SCNVector3] = [:]
        var legDeltas: [String: SCNVector3] = [:]
        var rootYaw: Float = 0
        var rootLift: Float = 0
        if let ag = activeGesture {
            let p = Float((now - ag.start) / ag.duration)
            if p >= 1 {
                activeGesture = nil
            } else {
                let env = sin(Float.pi * p)        // 0→1→0 for there-and-back moves
                let turn = p * p * (3 - 2 * p)      // smoothstep 0→1 for one-way spins
                switch ag.gesture {
                case .nod, .laugh: gHeadPitch = 0.22 * env
                case .shakeHead: gHeadYaw = sin(Float.pi * 2 * p) * 0.25
                case .tiltHead, .think: gHeadRoll = 0.26 * env
                case .leanIn: gSpinePitch = 0.14 * env
                case .leanBack: gSpinePitch = -0.12 * env
                case .bow:
                    // Fold forward across the whole spine chain (hold near the bottom of
                    // the bow) so it clearly reads as a bow rather than a small nod.
                    let fold = sin(Float.pi * min(p * 1.4, 1)) // reach the bow and hold
                    gSpinePitch = 0.5 * fold
                    gChestPitch = 0.5 * fold
                    gHeadPitch = 0.35 * fold
                case .twirl:
                    rootYaw = turn * Float.pi * 2
                    armDeltas["leftUpperArm"] = SCNVector3(0, 0, 0.5 * env)
                    armDeltas["rightUpperArm"] = SCNVector3(0, 0, -0.5 * env)
                case .spin:
                    rootYaw = turn * Float.pi * 2
                case .jump:
                    // Anticipation crouch → launch → airborne → landing absorb, with knee
                    // bend and arm swing so it isn't a rigid up/down slab.
                    func legs(_ knee: Float) {
                        legDeltas["leftLowerLeg"] = SCNVector3(knee, 0, 0)
                        legDeltas["rightLowerLeg"] = SCNVector3(knee, 0, 0)
                        legDeltas["leftUpperLeg"] = SCNVector3(-knee * 0.55, 0, 0)
                        legDeltas["rightUpperLeg"] = SCNVector3(-knee * 0.55, 0, 0)
                    }
                    if p < 0.22 {
                        let c = p / 0.22
                        rootLift = -0.05 * c
                        legs(0.6 * c)
                        gChestPitch = 0.12 * c
                        armDeltas["leftUpperArm"] = SCNVector3(0, 0, 0.12 * c)
                        armDeltas["rightUpperArm"] = SCNVector3(0, 0, -0.12 * c)
                    } else if p < 0.5 {
                        let l = (p - 0.22) / 0.28
                        let e = l * l * (3 - 2 * l)
                        rootLift = -0.05 + 0.5 * e
                        legs(0.6 * (1 - e))
                        armDeltas["leftUpperArm"] = SCNVector3(-0.35 * e, 0, 0)
                        armDeltas["rightUpperArm"] = SCNVector3(-0.35 * e, 0, 0)
                    } else if p < 0.8 {
                        let a = (p - 0.5) / 0.3
                        rootLift = 0.5 * (1 - a * a)
                        legs(0.2)
                        armDeltas["leftUpperArm"] = SCNVector3(-0.2 * (1 - a), 0, 0)
                        armDeltas["rightUpperArm"] = SCNVector3(-0.2 * (1 - a), 0, 0)
                    } else {
                        let absorb = sin(Float.pi * (p - 0.8) / 0.2)
                        rootLift = -0.05 * absorb
                        legs(0.5 * absorb)
                        gChestPitch = 0.1 * absorb
                    }
                case .dance:
                    rootYaw = sin(Float.pi * 4 * p) * 0.35
                    rootLift = abs(sin(Float.pi * 4 * p)) * 0.12
                    gHeadRoll = sin(Float.pi * 4 * p) * 0.15
                    armDeltas["leftUpperArm"] = SCNVector3(0, 0, 0.4 + sin(Float.pi * 4 * p) * 0.3)
                    armDeltas["rightUpperArm"] = SCNVector3(0, 0, -0.4 - sin(Float.pi * 4 * p) * 0.3)
                case .point:
                    // Straight arm extended out/forward — a clean point (no elbow fold).
                    armDeltas["rightUpperArm"] = SCNVector3(-0.9 * env, 0, -1.0 * env)
                case .stretch:
                    // Both arms reach overhead.
                    armDeltas["leftUpperArm"] = SCNVector3(-0.2 * env, 0, 2.5 * env)
                    armDeltas["rightUpperArm"] = SCNVector3(-0.2 * env, 0, -2.5 * env)
                    gSpinePitch = -0.08 * env
                case .wave:
                    // Raise a near-straight arm up and swing it. The earlier elbow fold
                    // rotated the forearm on the wrong axis and looked broken, so the
                    // elbow now stays relaxed.
                    let swing = sin(Float.pi * 8 * p) * 0.28 * env
                    armDeltas["rightUpperArm"] = SCNVector3(-0.25 * env, 0, -1.95 * env + swing)
                    gHeadRoll = 0.06 * env
                case .shrug:
                    let up = env
                    armDeltas["leftUpperArm"] = SCNVector3(0, 0, 0.32 * up)
                    armDeltas["rightUpperArm"] = SCNVector3(0, 0, -0.32 * up)
                    gHeadPitch = 0.06 * up
                case .handToChest:
                    // Keep the elbow low at the side and flex the forearm forward-and-up
                    // (+X = anatomical forward flex) so the hand rises across to the chest.
                    // The elbow must NOT hyperextend backward (−X), which reads as broken.
                    let m = sin(Float.pi * min(p * 1.4, 1))
                    armDeltas["rightUpperArm"] = SCNVector3(0, 0, -0.3 * m)
                    armDeltas["rightLowerArm"] = SCNVector3(1.75 * m, -0.25 * m, 0)
                    gHeadPitch = 0.05 * m
                default: gHeadPitch = 0.1 * env
                }
            }
        }

        setBone("upperChest", pitch: breathe * 0.018 + gChestPitch * 0.5, yaw: 0, roll: sway * 0.02 * idleAmp)
        setBone("chest", pitch: breathe * 0.012 + gChestPitch * 0.5, yaw: 0, roll: sway * 0.018 * idleAmp)
        setBone("spine", pitch: breathe * 0.008 + gSpinePitch, yaw: 0, roll: sway * 0.022 * idleAmp)

        if let hips = glbBones["hips"] {
            hips.node.position = SCNVector3(hips.restPosition.x,
                                            hips.restPosition.y + breathe * 0.004 * idleAmp,
                                            hips.restPosition.z)
            hips.node.eulerAngles = SCNVector3(hips.restEuler.x,
                                               hips.restEuler.y + sway * 0.02 * idleAmp,
                                               hips.restEuler.z)
        }

        setBone("neck",
                pitch: gHeadPitch * 0.4 + gazePitch * 0.3,
                yaw: gHeadYaw * 0.4 + gazeYaw * 0.3,
                roll: gHeadRoll * 0.3)
        setBone("head",
                pitch: gHeadPitch * 0.6 + gazePitch * 0.5 + breathe * 0.01 * idleAmp,
                yaw: gHeadYaw * 0.6 + gazeYaw * 0.5 + sway * 0.02 * idleAmp,
                roll: gHeadRoll * 0.7)

        setBone("leftEye", pitch: gazePitch * 0.5, yaw: gazeYaw * 0.6, roll: 0)
        setBone("rightEye", pitch: gazePitch * 0.5, yaw: gazeYaw * 0.6, roll: 0)

        // Arms and legs hold their relaxed rest pose unless a gesture is driving them.
        for key in ["leftUpperArm", "rightUpperArm", "leftLowerArm", "rightLowerArm",
                    "leftUpperLeg", "rightUpperLeg", "leftLowerLeg", "rightLowerLeg"] {
            let d = (armDeltas[key] ?? legDeltas[key]) ?? SCNVector3Zero
            setBone(key, pitch: d.x, yaw: d.y, roll: d.z)
        }

        // Whole-body movement: rotate/lift the entire model from its rest transform.
        if let root = glbRootNode {
            root.eulerAngles = SCNVector3(glbRootRestEuler.x,
                                          glbRootRestEuler.y + rootYaw,
                                          glbRootRestEuler.z)
            root.position = SCNVector3(glbRootRestPosition.x,
                                       glbRootRestPosition.y + rootLift,
                                       glbRootRestPosition.z)
        }

        updateGLBFace(dt, now: now)
        updateGLBBlink(now: now)
    }

    /// Idle micro-gestures appropriate to the current mood.
    private func idleGesturePool(for emotion: Emotion) -> [Gesture] {
        switch emotion {
        case .happy, .playful: return [.nod, .tiltHead, .laugh, .shrug]
        case .warm, .affectionate: return [.tiltHead, .nod, .handToChest]
        case .surprised: return [.nod, .tiltHead]
        case .sad: return [.leanBack, .tiltHead]
        case .thoughtful: return [.think, .tiltHead, .leanBack]
        case .concerned: return [.tiltHead, .leanBack]
        case .neutral: return [.tiltHead, .nod, .leanBack]
        }
    }

    /// How long to wait between idle micro-gestures — livelier moods fidget more often.
    private func idleGestureInterval(for emotion: Emotion) -> TimeInterval {
        switch emotion {
        case .happy, .playful: return TimeInterval.random(in: 4...8)
        case .sad, .thoughtful: return TimeInterval.random(in: 10...18)
        default: return TimeInterval.random(in: 7...14)
        }
    }

    /// Candidate spontaneous facial flickers appropriate to the current mood.
    private func exprFlickerOptions(for emotion: Emotion) -> [[String: Float]] {
        switch emotion {
        case .happy, .playful, .warm, .affectionate:
            return [["Fcl_MTH_Joy": 0.3, "Fcl_EYE_Joy": 0.25], ["Fcl_BRW_Fun": 0.3, "Fcl_MTH_Fun": 0.25]]
        case .sad:
            return [["Fcl_BRW_Sorrow": 0.3, "Fcl_EYE_Sorrow": 0.2]]
        case .thoughtful, .concerned:
            return [["Fcl_BRW_Sorrow": 0.25], ["Fcl_BRW_Angry": 0.2]]
        case .surprised, .neutral:
            return [["Fcl_BRW_Surprised": 0.35, "Fcl_EYE_Surprised": 0.12], ["Fcl_MTH_Joy": 0.22, "Fcl_EYE_Joy": 0.18]]
        }
    }

    /// Drives facial blend shapes every frame so the expression is alive: the held
    /// emotion eases toward its target, a slow ambient brow motion keeps a neutral face
    /// from looking frozen, and occasional flickers add spontaneity. All ambient motion
    /// is gated by the idle flag (suspended during speech) and Reduce Motion.
    private func updateGLBFace(_ dt: TimeInterval, now: TimeInterval) {
        guard hasGLB, !reduceMotion else { return }
        let lerp = min(Float(dt) * 5, 1)
        let ambientAmp: Float = isIdleEnabled ? 1 : 0

        glbFaceBrowPhase += Float(dt) * 0.7
        let browAmbient = (sin(glbFaceBrowPhase) * 0.5 + 0.5) * 0.07 * ambientAmp

        // Occasionally trigger a brief spontaneous expression, flavored by current mood.
        if ambientAmp > 0, glbExprFlicker == nil, now - glbLastExprFlicker > glbNextExprFlickerInterval {
            let options = exprFlickerOptions(for: currentEmotion)
            glbExprFlicker = ExprFlicker(start: now,
                                         dur: TimeInterval.random(in: 0.6...1.1),
                                         morphs: options.randomElement() ?? [:])
            glbLastExprFlicker = now
            glbNextExprFlickerInterval = TimeInterval.random(in: 6...12)
        }

        // Compose the desired weights: held emotion + ambient brow + active flicker.
        var desired = targetEmotionMorphs
        if browAmbient > 0.001 {
            desired["Fcl_BRW_Surprised", default: 0] += browAmbient
        }
        if let f = glbExprFlicker {
            let p = Float((now - f.start) / f.dur)
            if p >= 1 {
                glbExprFlicker = nil
            } else {
                let env = sin(Float.pi * p)
                for (k, v) in f.morphs { desired[k] = max(desired[k] ?? 0, v * env) }
            }
        }

        // Ease each morph toward its desired weight, releasing any that have settled.
        let keys = Set(currentEmotionMorphs.keys).union(desired.keys)
        for key in keys {
            let target = desired[key] ?? 0
            let cur = currentEmotionMorphs[key] ?? 0
            let next = cur + (target - cur) * lerp
            if abs(next) < 0.002 {
                currentEmotionMorphs[key] = nil
                setMorphWeight(named: key, weight: 0)
            } else {
                currentEmotionMorphs[key] = next
                setMorphWeight(named: key, weight: min(next, 1))
            }
        }

        // Lip-sync mouth: ease toward the active viseme and release every other mouth shape
        // so consecutive frames blend smoothly instead of snapping or stacking. A faster
        // lerp than the emotion layer keeps speech crisp.
        if !glbVisemeMorphNames.isEmpty {
            let mouthLerp = min(Float(dt) * 16, 1)
            let activeName = glbVisemeTarget?.name
            let activeWeight = glbVisemeTarget?.weight ?? 0
            for name in glbVisemeMorphNames {
                let target = (name == activeName) ? activeWeight : 0
                let cur = glbCurrentVisemeWeights[name] ?? 0
                let next = cur + (target - cur) * mouthLerp
                if abs(next) < 0.004 {
                    if cur != 0 { setMorphWeight(named: name, weight: 0) }
                    glbCurrentVisemeWeights[name] = nil
                } else {
                    glbCurrentVisemeWeights[name] = next
                    setMorphWeight(named: name, weight: min(next, 1))
                }
            }
        }
    }

    private func setBone(_ logical: String, pitch: Float, yaw: Float, roll: Float) {
        guard let bone = glbBones[logical] else { return }
        bone.node.eulerAngles = SCNVector3(bone.restEuler.x + pitch,
                                           bone.restEuler.y + yaw,
                                           bone.restEuler.z + roll)
    }

    private func setGLBGazeTarget(_ target: GazeTarget) {
        switch target {
        case .camera, .user:
            targetGazeYaw = 0
            targetGazePitch = 0
        case .away:
            // Glance off to the side and slightly up, as if thinking.
            targetGazeYaw = 0.32
            targetGazePitch = -0.12
        case .idle:
            targetGazeYaw = Float.random(in: -0.12...0.12)
            targetGazePitch = Float.random(in: -0.06...0.06)
        }
    }

    private func updateGLBBlink(now: TimeInterval) {
        guard now - glbLastBlink > glbNextBlinkInterval else { return }
        glbLastBlink = now
        glbNextBlinkInterval = TimeInterval.random(in: 2.5...5.5)

        let leftName = rigMapping?.blink.left ?? "blink_left"
        let rightName = rigMapping?.blink.right ?? "blink_right"
        setMorphWeight(named: leftName, weight: 1)
        setMorphWeight(named: rightName, weight: 1)
        setMorphWeight(named: "blink_left", weight: 1)
        setMorphWeight(named: "blink_right", weight: 1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) { [weak self] in
            guard let self else { return }
            self.setMorphWeight(named: leftName, weight: 0)
            self.setMorphWeight(named: rightName, weight: 0)
            self.setMorphWeight(named: "blink_left", weight: 0)
            self.setMorphWeight(named: "blink_right", weight: 0)
        }
    }

    // MARK: - Body mask for garments

    private func applyBodyMask(slot: WardrobeSlot, regions: Set<String>?, hidden: Bool) {
        guard let root = glbRootNode ?? headMeshNode else { return }
        guard let regions, !regions.isEmpty else {
            root.isHidden = hidden && slot == .headwear
            return
        }
        root.enumerateChildNodes { node, _ in
            guard let name = node.name, regions.contains(name) else { return }
            node.isHidden = hidden
        }
    }
}

enum AvatarError: Error {
    case garmentNotFound(String)
    case garmentLoadFailed
    case glbLoadFailed
}
