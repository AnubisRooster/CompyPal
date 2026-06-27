import SwiftUI
import RealityKit
import ARKit

@MainActor
class AvatarScene {
    let arView: ARView
    private(set) var headEntity: Entity?
    private var jawEntity: Entity?
    private var leftBrow: Entity?
    private var rightBrow: Entity?
    private var leftEye: Entity?
    private var rightEye: Entity?
    private var headAnchor: AnchorEntity?

    private let headColor: SimpleMaterial.Color
    private let browColor: SimpleMaterial.Color
    private let eyeWhiteColor: SimpleMaterial.Color

    init(headColor: SimpleMaterial.Color = UIColor(red: 0.9, green: 0.7, blue: 0.6, alpha: 1)) {
        self.headColor = headColor
        self.browColor = UIColor(red: 0.3, green: 0.2, blue: 0.15, alpha: 1)
        self.eyeWhiteColor = .white

        arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        let anchor = AnchorEntity(world: [0, 0, -2])
        arView.scene.anchors.append(anchor)
        headAnchor = anchor
        buildHead(anchor: anchor)
        setupLighting(anchor: anchor)
    }

    private func buildHead(anchor: AnchorEntity) {
        let headMesh = MeshResource.generateSphere(radius: 0.18)
        var headMat = SimpleMaterial(color: headColor, isMetallic: false)
        headMat.roughness = 0.6
        let head = ModelEntity(mesh: headMesh, materials: [headMat])
        head.name = "head"
        head.position = .zero
        anchor.addChild(head)
        headEntity = head

        let jawMesh = MeshResource.generateSphere(radius: 0.07)
        let jawMat = SimpleMaterial(color: headColor, isMetallic: false)
        let jaw = ModelEntity(mesh: jawMesh, materials: [jawMat])
        jaw.name = "jaw"
        jaw.position = [0, -0.1, 0.12]
        head.addChild(jaw)
        jawEntity = jaw

        let browLength: Float = 0.06
        let browWidth: Float = 0.015
        let browHeight: Float = 0.01
        let browMesh = MeshResource.generateBox(width: browLength, height: browHeight, depth: browWidth)
        let browMat = SimpleMaterial(color: browColor, isMetallic: false)

        let left = ModelEntity(mesh: browMesh, materials: [browMat])
        left.name = "leftBrow"
        left.position = [-0.06, 0.14, 0.16]
        head.addChild(left)
        leftBrow = left

        let right = ModelEntity(mesh: browMesh, materials: [browMat])
        right.name = "rightBrow"
        right.position = [0.06, 0.14, 0.16]
        head.addChild(right)
        rightBrow = right

        let eyeMesh = MeshResource.generateSphere(radius: 0.025)
        let eyeMat = SimpleMaterial(color: eyeWhiteColor, isMetallic: false)

        let leftEyeEntity = ModelEntity(mesh: eyeMesh, materials: [eyeMat])
        leftEyeEntity.name = "leftEye"
        leftEyeEntity.position = [-0.05, 0.05, 0.17]
        head.addChild(leftEyeEntity)
        leftEye = leftEyeEntity

        let rightEyeEntity = ModelEntity(mesh: eyeMesh, materials: [eyeMat])
        rightEyeEntity.name = "rightEye"
        rightEyeEntity.position = [0.05, 0.05, 0.17]
        head.addChild(rightEyeEntity)
        rightEye = rightEyeEntity

        let pupilMesh = MeshResource.generateSphere(radius: 0.01)
        let pupilMat = SimpleMaterial(color: UIColor(red: 0.2, green: 0.3, blue: 0.6, alpha: 1), isMetallic: false)

        let leftPupil = ModelEntity(mesh: pupilMesh, materials: [pupilMat])
        leftPupil.position = [0, 0, 0.03]
        leftEyeEntity.addChild(leftPupil)

        let rightPupil = ModelEntity(mesh: pupilMesh, materials: [pupilMat])
        rightPupil.position = [0, 0, 0.03]
        rightEyeEntity.addChild(rightPupil)
    }

    private func setupLighting(anchor: AnchorEntity) {
        let light = DirectionalLight()
        light.light.intensity = 2000
        light.light.color = .white
        light.position = [2, 3, 2]
        light.look(at: .zero, from: light.position, relativeTo: anchor)
        anchor.addChild(light)

        let fill = DirectionalLight()
        fill.light.intensity = 800
        fill.light.color = UIColor(white: 0.9, alpha: 1)
        fill.position = [-2, 1, 1]
        fill.look(at: .zero, from: fill.position, relativeTo: anchor)
        anchor.addChild(fill)
    }

    func applyAppearance(attributes: [(String, String)]) {
        for (key, value) in attributes {
            switch key {
            case "skin_tone":
                if let color = ParametricSchema.shared.color(for: "skin_tone", value: value) {
                    updateMaterial(on: headEntity, color: color)
                    updateMaterial(on: jawEntity, color: color)
                }
            case "eye_color":
                if let color = ParametricSchema.shared.color(for: "eye_color", value: value) {
                    updatePupilColor(color: color)
                }
            case "hair_color":
                if let color = ParametricSchema.shared.color(for: "hair_color", value: value) {
                    updateMaterial(on: leftBrow, color: color)
                    updateMaterial(on: rightBrow, color: color)
                }
            default: break
            }
        }
    }

    private func updateMaterial(on entity: Entity?, color: UIColor) {
        guard let model = entity as? ModelEntity else { return }
        var mat = SimpleMaterial(color: color, isMetallic: false)
        mat.roughness = 0.6
        model.model?.materials = [mat]
    }

    private func updatePupilColor(color: UIColor) {
        for child in [leftEye, rightEye] {
            guard let eye = child else { continue }
            for pupil in eye.children {
                guard let model = pupil as? ModelEntity else { continue }
                let mat = SimpleMaterial(color: color, isMetallic: false)
                model.model?.materials = [mat]
            }
        }
    }

    func applyExpression(emotion: String, mouthOpen: Float) {
        let w = BlendShapeWeights.weights(for: emotion)
        let jaw = max(w.jawOpen, w.mouthOpen, mouthOpen)

        jawEntity?.move(to: Transform(
            scale: .one,
            rotation: simd_quatf(angle: jaw * 0.3, axis: [1, 0, 0]),
            translation: [0, -0.1 - jaw * 0.03, 0.12]
        ), relativeTo: headEntity, duration: 0.06, timingFunction: .easeInOut)

        let browUp = w.browInnerUp * 0.06 - w.browDown * 0.03
        let browScale: Float = 1.0 - w.browDown * 0.3

        leftBrow?.move(to: Transform(
            scale: [1, browScale, 1],
            rotation: simd_quatf(angle: -browUp * 2, axis: [1, 0, 0]),
            translation: [-0.06, 0.14 + browUp, 0.16]
        ), relativeTo: headEntity, duration: 0.06, timingFunction: .easeInOut)

        rightBrow?.move(to: Transform(
            scale: [1, browScale, 1],
            rotation: simd_quatf(angle: -browUp * 2, axis: [1, 0, 0]),
            translation: [0.06, 0.14 + browUp, 0.16]
        ), relativeTo: headEntity, duration: 0.06, timingFunction: .easeInOut)

        let eyeScale: Float = 1.0 - w.eyeWide * 0.3
        leftEye?.move(to: Transform(
            scale: [1, max(eyeScale, 0.5), 1],
            rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
            translation: [-0.05, 0.05, 0.17]
        ), relativeTo: headEntity, duration: 0.06, timingFunction: .easeInOut)

        rightEye?.move(to: Transform(
            scale: [1, max(eyeScale, 0.5), 1],
            rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
            translation: [0.05, 0.05, 0.17]
        ), relativeTo: headEntity, duration: 0.06, timingFunction: .easeInOut)
    }
}

struct AvatarView: UIViewRepresentable {
    let emotion: String
    let mouthOpen: Float
    let appearance: [(String, String)]
    let referenceImageData: Data?

    func makeUIView(context: Context) -> ARView {
        let scene = context.coordinator.avatarScene
        scene.applyAppearance(attributes: appearance)
        if let data = referenceImageData {
            context.coordinator.referenceHash = data.hashValue
            applyTexture(data: data, scene: scene)
        }
        return scene.arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        let scene = context.coordinator.avatarScene
        scene.applyAppearance(attributes: appearance)
        if let data = referenceImageData, data.hashValue != context.coordinator.referenceHash {
            context.coordinator.referenceHash = data.hashValue
            applyTexture(data: data, scene: scene)
        }
        scene.applyExpression(emotion: emotion, mouthOpen: mouthOpen)
    }

    private func applyTexture(data: Data, scene: AvatarScene) {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else { return }
        Task { @MainActor in
            guard let texture = try? await TextureResource.generate(from: cgImage, options: .init(semantic: .color)) else { return }
            var mat = PhysicallyBasedMaterial()
            mat.baseColor = .init(texture: MaterialParameters.Texture(texture))
            mat.roughness = 0.8
            guard let head = scene.headEntity as? ModelEntity else { return }
            head.model?.materials = [mat]
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    class Coordinator {
        let avatarScene = AvatarScene()
        var referenceHash: Int = 0
    }
}

#Preview {
    AvatarView(emotion: "warm", mouthOpen: 0, appearance: [("skin_tone", "light"), ("eye_color", "blue"), ("hair_color", "brown")], referenceImageData: nil)
        .frame(height: 300)
}
