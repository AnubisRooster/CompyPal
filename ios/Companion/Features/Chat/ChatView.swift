import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var inputText = ""

    init(companion: CompanionInfo) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(companion: companion))
    }

    var body: some View {
        VStack(spacing: 0) {
            avatarSection

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding()
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            inputBar
        }
        .navigationTitle(viewModel.companion.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isSpeaking {
                Button("Stop", systemImage: "speaker.wave.2.fill") {
                    viewModel.stopSpeaking()
                }
            }
        }
        .task { await viewModel.load() }
    }

    private var avatarSection: some View {
        AvatarView(emotion: viewModel.currentEmotion, mouthOpen: viewModel.mouthOpen)
            .frame(height: 200)
            .overlay(alignment: .topTrailing) {
                if viewModel.isSpeaking {
                    Label("Speaking", systemImage: "waveform")
                        .font(.caption)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(.rect(cornerRadius: 8))
                        .padding(8)
                }
            }
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            Button(action: { viewModel.toggleVoiceInput() }) {
                Image(systemName: viewModel.isListening ? "waveform" : "mic")
                    .font(.title2)
                    .foregroundStyle(viewModel.isListening ? .red : .primary)
            }
            .disabled(viewModel.isStreaming)

            TextField("Message...", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.isStreaming || viewModel.isListening)

            if viewModel.isListening {
                Text(viewModel.messages.last?.text ?? "")
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Send") {
                let text = inputText
                inputText = ""
                Task { await viewModel.sendText(text) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isStreaming)
        }
        .padding()
        .background(.bar)
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
                Text(message.text)
                    .padding(12)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 16, style: .continuous))
            } else if message.role == "assistant" {
                Text(message.text)
                    .padding(12)
                    .background(.gray.opacity(0.15))
                    .clipShape(.rect(cornerRadius: 16, style: .continuous))
                Spacer()
            } else {
                Text(message.text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
