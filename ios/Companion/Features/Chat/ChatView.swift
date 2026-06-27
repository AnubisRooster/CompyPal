import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var inputText = ""

    init(companionId: String, userId: String) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(companionId: companionId, userId: userId))
    }

    var body: some View {
        VStack(spacing: 0) {
            avatarSection

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg)
                    }
                }
                .padding()
            }

            inputBar
        }
    }

    private var avatarSection: some View {
        AvatarView(emotion: viewModel.currentEmotion,
                   mouthOpen: viewModel.mouthOpen,
                   avatarUrl: viewModel.avatarUrl)
            .frame(height: 250)
            .overlay(alignment: .topTrailing) {
                Text(viewModel.currentEmotion)
                    .font(.caption)
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(.rect(cornerRadius: 8))
                    .padding(8)
            }
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            Button(action: { viewModel.toggleVoiceInput() }) {
                Image(systemName: viewModel.isListening ? "waveform" : "mic")
                    .font(.title2)
                    .foregroundStyle(viewModel.isListening ? .red : .primary)
            }

            TextField("Message...", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.isListening)

            Button("Send") {
                guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                viewModel.sendText(inputText)
                inputText = ""
            }
            .buttonStyle(.borderedProminent)
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
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
            }
        }
    }
}

#Preview {
    ChatView(companionId: "test", userId: "user")
}
