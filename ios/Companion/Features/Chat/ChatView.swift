import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var inputText = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg)
                    }
                }
                .padding()
            }

            HStack(spacing: 12) {
                TextField("Message...", text: $inputText)
                    .textFieldStyle(.roundedBorder)

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

#Preview { ChatView() }
