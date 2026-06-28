import SwiftUI

struct DevelopmentAvatarPreview: View {
    @StateObject private var viewModel = AvatarViewModel()
    @State private var selectedTab = 0
    @State private var animateSequence = false

    var body: some View {
        VStack(spacing: 0) {
            CompanionAvatarView(viewModel: viewModel, showDebug: true)
                .frame(height: 400)

            Picker("Test Mode", selection: $selectedTab) {
                Text("Emotions").tag(0)
                Text("Gestures").tag(1)
                Text("Sequence").tag(2)
                Text("Appearance").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollView {
                switch selectedTab {
                case 0: emotionGrid
                case 1: gestureGrid
                case 2: sequenceView
                case 3: appearanceView
                default: EmptyView()
                }
            }
        }
        .onAppear {
            viewModel.applyAppearance([
                ("skin_tone", "light"),
                ("eye_color", "blue"),
                ("hair_color", "brown"),
            ])
        }
    }

    // MARK: - Emotion Grid

    private var emotionGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
            ForEach(Emotion.allCases, id: \.self) { emotion in
                Button(emotion.rawValue.capitalized) {
                    viewModel.debugPlayEmotion(emotion)
                }
                .buttonStyle(.bordered)
                .tint(viewModel.currentEmotion == emotion ? .blue : .gray)
            }
        }
        .padding()
    }

    // MARK: - Gesture Grid

    private var gestureGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
            ForEach(Gesture.allCases, id: \.self) { gesture in
                Button(gesture.rawValue.replacingOccurrences(of: "_", with: " ").capitalized) {
                    viewModel.debugPlayGesture(gesture)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    // MARK: - Sequence

    private var sequenceView: some View {
        VStack(spacing: 12) {
            Text("Demo Sequence")
                .font(.headline)

            Button(animateSequence ? "Stop" : "Play Sequence") {
                animateSequence.toggle()
                if animateSequence { runSequence() }
            }
            .buttonStyle(.borderedProminent)

            Button("Test Performance Track") {
                testPerformanceTrack()
            }
            .buttonStyle(.bordered)

            Button("Simulate Speech") {
                simulateSpeech()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func runSequence() {
        let emotions: [Emotion] = [.neutral, .warm, .happy, .surprised, .thoughtful, .sad, .playful, .neutral]
        var delay: TimeInterval = 0

        let vm = viewModel
        let seq = Binding(get: { self.animateSequence }, set: { self.animateSequence = $0 })

        for (i, emotion) in emotions.enumerated() {
            let d = delay
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                guard seq.wrappedValue else { return }
                vm.debugPlayEmotion(emotion)
            }
            delay += 1.2
            if i > 0 {
                let gesture = Gesture.allCases.randomElement() ?? .idle
                DispatchQueue.main.asyncAfter(deadline: .now() + d + 0.3) {
                    guard seq.wrappedValue else { return }
                    vm.debugPlayGesture(gesture)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.5) {
            seq.wrappedValue = false
        }
    }

    private func testPerformanceTrack() {
        let track = PerformanceTrack(
            text: "I'm really happy to see you today! I was just thinking about our last conversation.",
            emotion: "warm",
            beats: [
                PerformanceBeat(at: 5, emotion: "happy", gesture: "wave", gaze: "user"),
                PerformanceBeat(at: 15, emotion: "warm", gesture: "hand_to_chest", gaze: "user"),
                PerformanceBeat(at: 28, emotion: "thoughtful", gesture: "tilt_head", gaze: "away"),
            ]
        )
        viewModel.beginSpeaking(text: track.text, track: track)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.viewModel.endSpeaking()
        }
    }

    private func simulateSpeech() {
        viewModel.beginSpeaking(text: "Hello, how are you today?", track: nil)
        let chars = Array("Hello, how are you today?")
        let vm = viewModel
        for (i, char) in chars.enumerated() {
            let delay = Double(i) * 0.06
            let viseme: Viseme = char.isLetter ? [.aa, .ee, .ih, .oh, .ou].randomElement()! : .sil
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                vm.controller.setViseme(viseme, weight: 0.7)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(chars.count) * 0.06 + 0.2) {
            self.viewModel.endSpeaking()
        }
    }

    // MARK: - Appearance

    private var appearanceView: some View {
        VStack(spacing: 16) {
            Text("Appearance Attributes")
                .font(.headline)

            ForEach(ParametricSchema.shared.attributes, id: \.key) { attr in
                VStack(alignment: .leading) {
                    Text(attr.label)
                        .font(.caption)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(attr.values.keys.sorted()), id: \.self) { value in
                                Button(value.capitalized) {
                                    var attrs = viewModel.appearanceAttributes
                                    attrs.removeAll { $0.0 == attr.key }
                                    attrs.append((attr.key, value))
                                    viewModel.applyAppearance(attrs)
                                }
                                .buttonStyle(.bordered)
                                .tint(viewModel.appearanceAttributes.first(where: { $0.0 == attr.key && $0.1 == value }) != nil ? .blue : .gray)
                            }
                        }
                    }
                }
            }

            Divider()

            Text("Stage")
                .font(.headline)
            Picker("Stage", selection: $viewModel.stage) {
                Text("Acquaintance").tag("acquaintance")
                Text("Friend").tag("friend")
                Text("Confidant").tag("confidant")
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.stage) { _, newValue in
                viewModel.setStage(newValue)
            }
        }
        .padding()
    }
}

#Preview {
    DevelopmentAvatarPreview()
}
