import SwiftUI
import AVFoundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentEmotion: String = "neutral"
    @Published var isSpeaking = false
    @Published var isListening = false
    @Published var mouthOpen: Float = 0
    @Published var avatarUrl: String?
    @Published var companionId: String
    @Published var userId: String

    private let apiClient = APIClient()
    private let audioPlayer = AudioPlayerService()
    private let audioRecorder = AudioRecorderService()
    private var pendingText = ""
    private var lipSyncTimer: Timer?

    init(companionId: String, userId: String) {
        self.companionId = companionId
        self.userId = userId
        connect()
    }

    func connect() {
        Task {
            await apiClient.connectChat(
                companionId: companionId,
                userId: userId,
                onToken: { [weak self] token in
                    Task { @MainActor in
                        self?.appendToken(token)
                    }
                },
                onAudioChunk: { [weak self] seq, data in
                    Task { @MainActor in
                        self?.audioPlayer.playChunk(base64Data: data)
                    }
                },
                onEmotion: { [weak self] emotion in
                    Task { @MainActor in
                        self?.currentEmotion = emotion
                    }
                },
                onAppearanceUpdate: { [weak self] url, attrs in
                    Task { @MainActor in
                        self?.avatarUrl = url
                    }
                },
                onDone: { [weak self] in
                    Task { @MainActor in
                        self?.isSpeaking = false
                        self?.stopLipSync()
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor in
                        self?.messages.append(ChatMessage(role: "system", text: "Error: \(error)"))
                    }
                }
            )
        }
    }

    func sendText(_ text: String) {
        messages.append(ChatMessage(role: "user", text: text))
        pendingText = ""
        Task {
            await apiClient.sendMessage(text)
        }
        isSpeaking = true
        startLipSync()
    }

    func toggleVoiceInput() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    private func startListening() {
        Task {
            let granted = await audioRecorder.requestPermission()
            guard granted else { return }
            isListening = true
            audioRecorder.startRecording { [weak self] transcript in
                Task { @MainActor in
                    self?.pendingText = transcript
                }
            }
        }
    }

    private func stopListening() {
        audioRecorder.stopRecording()
        isListening = false
        if !pendingText.isEmpty {
            sendText(pendingText)
        }
    }

    private func appendToken(_ token: String) {
        if messages.last?.role == "assistant" {
            var last = messages.removeLast()
            last.text += token
            messages.append(last)
        } else {
            messages.append(ChatMessage(role: "assistant", text: token))
        }
    }

    private func startLipSync() {
        stopLipSync()
        lipSyncTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let amp = self.audioPlayer.averagePower
                self.mouthOpen = amp > 0.01 ? min(amp * 2, 1) : 0
            }
        }
    }

    private func stopLipSync() {
        lipSyncTimer?.invalidate()
        lipSyncTimer = nil
        mouthOpen = 0
    }

    deinit {
        lipSyncTimer?.invalidate()
        lipSyncTimer = nil
        Task { [apiClient] in
            await apiClient.disconnectChat()
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    var text: String
}
