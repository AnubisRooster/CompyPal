import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var inputText = ""
    @FocusState private var isFocused: Bool

    init(companion: CompanionInfo) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(companion: companion))
    }

    var body: some View {
        VStack(spacing: 0) {
            offlineBanner
            companionHeader
            scrollView
            inputBar
        }
        .navigationTitle(viewModel.companion.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    Button(action: { viewModel.stopSpeaking() }) {
                        Image(systemName: "speaker.slash")
                            .accessibilityLabel("Stop speaking")
                    }
                    .disabled(!viewModel.isSpeaking)
                    .opacity(viewModel.isSpeaking ? 1 : 0.3)

                    Button(action: { viewModel.cancelStream() }) {
                        Image(systemName: "stop.circle")
                            .accessibilityLabel("Cancel response")
                    }
                    .disabled(!viewModel.isStreaming)
                    .opacity(viewModel.isStreaming ? 1 : 0.3)
                }
            }
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var offlineBanner: some View {
        if viewModel.isOffline {
            HStack {
                Image(systemName: "wifi.slash")
                Text("You're offline. Chat requires an internet connection.")
                    .font(.caption)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.2))
            .accessibilityHint("Internet connection required for chat")
        }
    }

    private var companionHeader: some View {
        CompanionAvatarView(viewModel: viewModel.avatarViewModel)
            .frame(height: 360)
            .accessibilityLabel(avatarAccessibilityLabel)
            .accessibilityAddTraits(.isImage)
    }

    private var avatarAccessibilityLabel: String {
        let name = viewModel.companion.name
        let state: String
        if viewModel.isSpeaking { state = "Speaking" }
        else if viewModel.isListening { state = "Listening" }
        else if viewModel.avatarViewModel.isThinking { state = "Thinking" }
        else { state = "Idle" }
        return "\(name) avatar. \(state)"
    }

    private var scrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg, isStreaming: viewModel.isStreaming && msg.id == viewModel.messages.last?.id)
                    }
                    if viewModel.isReconnecting {
                        HStack {
                            Label("Reconnecting...", systemImage: "antenna.radiowaves.left.and.right")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.leading)
                            Spacer()
                        }
                    } else if viewModel.isStreaming {
                        HStack {
                            DotLoader()
                                .padding(.leading)
                            Spacer()
                        }
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.messages.count) { _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            Button(action: { viewModel.toggleVoiceInput() }) {
                Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
                    .foregroundColor(viewModel.isListening ? .red : .primary)
                    .accessibilityLabel(viewModel.isListening ? "Stop recording" : "Start recording")
            }

            TextField("Type a message...", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .disabled(viewModel.isListening)
                .onChange(of: inputText) { _ in
                    viewModel.avatarViewModel.onInputChanged(inputText)
                }

            if viewModel.isStreaming {
                Button("Cancel") { viewModel.cancelStream() }
                    .buttonStyle(.bordered)
            } else {
                Button("Send") {
                    let text = inputText
                    inputText = ""
                    isFocused = false
                    Task { await viewModel.sendText(text) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isOffline || !viewModel.hasApiKey)
            }
        }
        .padding()
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    var isStreaming: Bool = false

    var body: some View {
        HStack {
            if message.role == "user" { Spacer(minLength: 60) }
            Text(message.text)
                .padding(12)
                .foregroundColor(message.role == "user" ? .white : .primary)
                .background(message.role == "user" ? Color.blue : Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityLabel("\(message.role == "user" ? "You" : "Companion"): \(message.text)")
            if message.role == "assistant" { Spacer(minLength: 60) }
        }
    }
}

struct DotLoader: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.gray)
                    .opacity(0.5)
            }
        }
        .accessibilityHidden(true)
    }
}

