import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []

    init() {}

    func sendText(_ text: String) {
        messages.append(ChatMessage(role: "user", text: text))
        messages.append(ChatMessage(role: "assistant", text: "Companion chat coming in Phase 1."))
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    var text: String
}
