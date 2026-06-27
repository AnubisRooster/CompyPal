import SwiftUI
import RealityKit
import ARKit

@MainActor
class AvatarScene {
    let arView: ARView
    private var loaded = false
    private var loadedTask: Task<Void, Never>?
    private var currentUrl: String?

    init() {
        arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        let anchor = AnchorEntity(world: [0, -1, -2])
        arView.scene.anchors.append(anchor)

        let defaultHead = ModelEntity(mesh: .generateSphere(radius: 0.15), materials: [{
            var m = SimpleMaterial()
            m.color = .init(tint: .systemBlue)
            return m
        }()])
        defaultHead.name = "head"
        anchor.addChild(defaultHead)
        headEntity = defaultHead
        headAnchor = anchor

        let light = DirectionalLight()
        light.light.intensity = 1000
        light.light.color = .white
        light.position = [2, 3, 2]
        anchor.addChild(light)

        loadAvatar(anchor: anchor, url: "https://models.readyplayer.me/6185a4acfb622cf1cdc49348.glb")
    }

    private weak var headEntity: ModelEntity?
    private weak var headAnchor: AnchorEntity?

    func reloadAvatar(url: String) {
        guard url != currentUrl, let anchor = headAnchor else { return }
        currentUrl = url
        loadAvatar(anchor: anchor, url: url)
    }

    private func loadAvatar(anchor: AnchorEntity, url: String) {
        loadedTask?.cancel()
        loadedTask = Task {
            guard let url = URL(string: url) else { return }
            do {
                let model = try await ModelEntity.loadModel(contentsOf: url)
                model.name = "head"
                model.scale = [0.01, 0.01, 0.01]

                for child in anchor.children {
                    if child.name == "head" || child is ModelEntity {
                        anchor.removeChild(child)
                    }
                }

                for child in anchor.children {
                    if child is DirectionalLight { continue }
                    anchor.removeChild(child)
                }

                anchor.addChild(model)
                headEntity = model

                let light = DirectionalLight()
                light.light.intensity = 1000
                light.light.color = .white
                light.position = [2, 3, 2]
                anchor.addChild(light)

                if let scene = model.availableAnimations.first {
                    model.playAnimation(scene.repeat())
                }

                loaded = true
            } catch {
                let fallback = ModelEntity(mesh: .generateSphere(radius: 0.15), materials: [{
                    var m = SimpleMaterial()
                    m.color = .init(tint: .systemGray)
                    return m
                }()])
                fallback.name = "head"
                anchor.addChild(fallback)
                headEntity = fallback
            }
        }
    }

    func applyExpression(emotion: String, mouthOpen: Float) {
        guard let entity = arView.scene.anchors.first?.children.first(where: { $0.name == "head" }) as? ModelEntity
        else { return }

        let w = BlendShapeWeights.weights(for: emotion)
        var s: Float = 1.0
        let open = max(w.jawOpen, w.mouthOpen, mouthOpen)
        if open > 0.05 { s = 1.0 + open * 0.12 }
        let tilt = w.browInnerUp * 0.03 - w.browDown * 0.02
        let rot = simd_quatf(angle: tilt, axis: [1, 0, 0])
        entity.move(to: Transform(scale: [s, s, s], rotation: rot, translation: .zero),
                     relativeTo: entity.parent, duration: 0.08, timingFunction: .easeInOut)
    }
}

struct AvatarView: UIViewRepresentable {
    let emotion: String
    let mouthOpen: Float
    let avatarUrl: String?

    func makeUIView(context: Context) -> ARView {
        context.coordinator.avatarScene.arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        if let url = avatarUrl, !url.isEmpty {
            context.coordinator.avatarScene.reloadAvatar(url: url)
        }
        context.coordinator.avatarScene.applyExpression(emotion: emotion, mouthOpen: mouthOpen)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    class Coordinator {
        let avatarScene = AvatarScene()
    }
}

#Preview {
    AvatarView(emotion: "warm", mouthOpen: 0, avatarUrl: nil)
        .frame(height: 300)
}
