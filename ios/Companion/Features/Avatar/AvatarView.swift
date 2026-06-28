import SwiftUI
import SceneKit

struct AvatarSceneView: UIViewRepresentable {
    let sceneView: SCNView
    let onTap: () -> Void

    func makeUIView(context: Context) -> SCNView {
        sceneView.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tap)
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    @MainActor
    class Coordinator {
        let onTap: () -> Void
        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            onTap()
        }
    }
}

struct CompanionAvatarView: View {
    @ObservedObject var viewModel: AvatarViewModel
    var showDebug: Bool = false

    var body: some View {
        ZStack {
            AvatarSceneView(sceneView: viewModel.controller.sceneView, onTap: {
                viewModel.handleTap()
            })

            if showDebug {
                debugOverlay
            }
        }
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    @ViewBuilder
    private var debugOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Avatar Debug")
                .font(.caption.bold())
                .foregroundColor(.white)

            HStack {
                Text("Emotion:")
                    .font(.caption2)
                Picker("", selection: $viewModel.debugState.currentEmotion) {
                    ForEach(Emotion.allCases, id: \.self) { em in
                        Text(em.rawValue).tag(em)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.debugState.currentEmotion) { _, newValue in
                    viewModel.debugPlayEmotion(newValue)
                }
            }

            HStack {
                Text("Gesture:")
                    .font(.caption2)
                Picker("", selection: $viewModel.debugState.currentGesture) {
                    ForEach(Gesture.allCases, id: \.self) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.debugState.currentGesture) { _, newValue in
                    viewModel.debugPlayGesture(newValue)
                }
            }

            HStack {
                Text("Gaze:")
                    .font(.caption2)
                Picker("", selection: $viewModel.debugState.currentGaze) {
                    ForEach([GazeTarget.camera, .user, .away, .idle], id: \.self) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.debugState.currentGaze) { _, newValue in
                    viewModel.debugSetGaze(newValue)
                }
            }

            Toggle("Idle enabled", isOn: $viewModel.debugState.isIdleEnabled)
                .font(.caption2)
                .onChange(of: viewModel.debugState.isIdleEnabled) { _, newValue in
                    viewModel.idleSystem.setEnabled(newValue)
                }

            Slider(value: $viewModel.debugState.mouthOpen, in: 0...1) {
                Text("Mouth: \(String(format: "%.2f", viewModel.debugState.mouthOpen))")
                    .font(.caption2)
            }
            .onChange(of: viewModel.debugState.mouthOpen) { _, newValue in
                viewModel.controller.setViseme(.aa, weight: newValue)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}

#Preview {
    CompanionAvatarView(viewModel: AvatarViewModel(), showDebug: true)
        .frame(height: 300)
}
