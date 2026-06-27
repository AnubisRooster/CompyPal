import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isStreaming = false
    @Published var errorMessage: String?
    @Published var isSpeaking = false
    @Published var isListening = false
    @Published var mouthOpen: Float = 0
    @Published var currentEmotion = "neutral"

    var companion: CompanionInfo
    @Published var appearanceVersion = 0

    private let store = MemoryStore()
    private let client = OpenRouterClient()
    private let extractor: MemoryExtractor
    private let keychain = KeychainService()
    private let catalogCache = CatalogCache()
    private let ttsEngine = TTSEngine()
    private let audioRecorder = AudioRecorderService()
    private let appearanceParser: AppearanceIntentParser
    private let appearanceApplier: AppearanceApplier

    private var userId: Int64 = 1
    private var chatCandidates: [CatalogEntry] = []
    private var pendingTranscript = ""

    init(companion: CompanionInfo) {
        self.companion = companion
        self.extractor = MemoryExtractor(client: client, store: store)
        self.appearanceParser = AppearanceIntentParser(client: client)
        self.appearanceApplier = AppearanceApplier(store: store)
    }

    func load() async {
        userId = (try? await store.ensureUser()) ?? 1
        let recent = (try? await store.recentTurns(companionId: companion.id, limit: 20)) ?? []
        messages = recent.map { ChatMessage(role: $0.role, text: $0.text) }
        await loadApiKey()
        await loadChatCandidates()
    }

    func sendText(_ text: String) async {
        guard !isStreaming, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        errorMessage = nil
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        messages.append(ChatMessage(role: "user", text: trimmed))
        let turnId = (try? await store.insertTurn(companionId: companion.id, role: "user", text: trimmed)) ?? 0

        isStreaming = true
        messages.append(ChatMessage(role: "assistant", text: ""))
        let msgIndex = messages.count - 1

        let stage = (try? await store.relationshipStage(companionId: companion.id)) ?? "acquaintance"
        let memories = (try? await store.salientMemories(userId: userId, companionId: companion.id)) ?? []
        let systemPrompt = PersonaAssembler.systemPrompt(
            companionName: companion.name,
            traits: companion.traits,
            memories: memories,
            appearance: companion.appearance,
            stage: stage
        )

        var fullReply = ""
        var succeeded = false

        for candidate in chatCandidates {
            guard isStreaming else { break }
            do {
                let chatMessages = buildChatMessages(system: systemPrompt, history: messages, newUserText: trimmed)
                var streamed = ""
                for try await delta in await client.streamChat(model: candidate.id, messages: chatMessages) {
                    streamed += delta
                    fullReply += delta
                    messages[msgIndex].text = streamed
                }
                succeeded = true
                break
            } catch {
                errorMessage = "\(candidate.id) failed: \(error.localizedDescription)"
                try? await catalogCache.clear()
                continue
            }
        }

        isStreaming = false

        guard succeeded, !fullReply.trimmingCharacters(in: .whitespaces).isEmpty else {
            if !succeeded {
                messages[msgIndex].text = "⚠️ All models failed. Check your API key or try refreshing the model catalog."
            }
            return
        }

        let assistantTurnId = (try? await store.insertTurn(companionId: companion.id, role: "assistant", text: fullReply)) ?? 0

        let catalog = (await catalogCache.load())?.entries ?? []
        Task {
            try? await extractor.extractAndStore(
                userId: userId, companionId: companion.id, turnId: turnId,
                userText: trimmed, assistantText: fullReply, catalog: catalog
            )
        }
        await checkStagePromotion()
        await handleAppearanceIntent(userText: trimmed, catalog: catalog)
        speakReply(fullReply)
    }

    func toggleVoiceInput() {
        if isListening { stopListening() }
        else { startListening() }
    }

    private func startListening() {
        Task {
            let granted = await audioRecorder.requestPermission()
            guard granted else { return }
            isListening = true
            audioRecorder.startRecording { [weak self] transcript in
                Task { @MainActor in
                    self?.pendingTranscript = transcript
                }
            }
        }
    }

    private func stopListening() {
        audioRecorder.stopRecording()
        isListening = false
        if !pendingTranscript.trimmingCharacters(in: .whitespaces).isEmpty {
            let text = pendingTranscript
            pendingTranscript = ""
            Task { await sendText(text) }
        }
    }

    private func speakReply(_ text: String) {
        ttsEngine.speak(
            text,
            voiceId: "com.apple.voice.compact.en-US.Samantha",
            pitch: 1.0,
            rate: 0.5
        ) { [weak self] mouthValue in
            Task { @MainActor in
                self?.mouthOpen = mouthValue
            }
        }
        isSpeaking = true

        Task {
            while ttsEngine.isSpeaking {
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
            isSpeaking = false
            mouthOpen = 0
        }
    }

    func stopSpeaking() {
        ttsEngine.stop()
        isSpeaking = false
        mouthOpen = 0
    }

    private func handleAppearanceIntent(userText: String, catalog: [CatalogEntry]) async {
        guard let delta = try? await appearanceParser.parse(
            userText: userText,
            currentAppearance: companion.appearance,
            catalog: catalog
        ) else { return }

        let result = (try? await appearanceApplier.apply(delta: delta, companionId: companion.id)) ?? delta

        if let value = result.value, result.declined != true {
            let updated = try? await store.companion(id: companion.id)
            companion = updated ?? companion
            appearanceVersion += 1

            let confirmMsg = ChatMessage(role: "assistant", text: "Got it! Changing \(result.attribute) to \(value).")
            messages.append(confirmMsg)
            speakReply(confirmMsg.text)
        } else if let suggestion = result.suggestion {
            let declineMsg = ChatMessage(role: "assistant", text: suggestion)
            messages.append(declineMsg)
            speakReply(declineMsg.text)
        }
    }

    private func loadApiKey() async {
        if let key = await keychain.read(key: KeychainService.apiKeyAccount), !key.isEmpty {
            await client.setKey(key)
        }
    }

    private func loadChatCandidates() async {
        if let cached = await catalogCache.load() {
            chatCandidates = SelectionPolicy(role: .chat, catalog: cached.entries, pinnedModelId: nil).rank()
        }
        if chatCandidates.isEmpty {
            let seed = CatalogEntry(
                id: "openai/gpt-4o-mini",
                name: "GPT-4o Mini",
                pricing: .zero,
                contextLength: 128000,
                modalities: Modalities(input: ["text"], output: ["text"]),
                supportedParameters: ["streaming", "tools"]
            )
            chatCandidates = [seed]
        }
    }

    private func buildChatMessages(system: String, history: [ChatMessage], newUserText: String) -> [Message] {
        var msgs = [Message(role: "system", content: system)]
        for msg in history {
            msgs.append(Message(role: msg.role, content: msg.text))
        }
        msgs.append(Message(role: "user", content: newUserText))
        return msgs
    }

    private func checkStagePromotion() async {
        let stageThresholds: [(String, Int)] = [
            ("acquaintance", 5),
            ("friend", 20),
        ]
        for (stage, threshold) in stageThresholds {
            if companion.relationshipStage == stage, companion.turnCount >= threshold {
                try? await store.promoteStage(companionId: companion.id)
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    var text: String
}
