import SwiftUI
import AVFoundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isStreaming = false
    @Published var errorMessage: String?
    @Published var isSpeaking = false
    @Published var isListening = false
    @Published var hasApiKey = false
    @Published var isOffline = false

    var companion: CompanionInfo
    @Published var appearanceVersion = 0

    let avatarViewModel = AvatarViewModel()

    private let store = MemoryStore()
    let client = OpenRouterClient()
    private let extractor: MemoryExtractor
    private let keychain = KeychainService()
    private let catalogCache = CatalogCache()
    private let ttsEngine = TTSEngine()
    private let audioRecorder = AudioRecorderService()
    private let appearanceParser: AppearanceIntentParser
    private let appearanceApplier: AppearanceApplier
    private lazy var imageGenService = ImageGenerationService(client: client)

    private var userId: Int64 = 1
    private var chatCandidates: [CatalogEntry] = []
    private var pendingTranscript = ""
    private var streamTask: Task<Void, Never>?

    private let intentPatterns: [Regex<AnyRegexOutput>] = [
        try! Regex("change (my|the|this) (hair|eye|skin|look|style)"),
        try! Regex("(dye|cut|color|style|change) my (hair|eyebrow)"),
        try! Regex("give me (a|an) (new|different) (look|style|haircut)"),
        try! Regex("try (on|out) a (new|different) (look|style|color)"),
        try! Regex("(want|like|love) to (change|try|have) (my|a)"),
        try! Regex("what (do|would) i (look like|wear|try)"),
    ]

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
        isOffline = !NetworkMonitor.shared.isConnected

        avatarViewModel.applyAppearance(companion.appearance)
        avatarViewModel.setPersonalityTraits(companion.traits)
        let stage = (try? await store.relationshipStage(companionId: companion.id)) ?? "acquaintance"
        avatarViewModel.setStage(stage)
        if let imgData = await imageGenService.cachedImageData(companionId: companion.id) {
            avatarViewModel.applyReferenceImage(imgData)
        }
        if let glbAsset = companion.glbAsset {
            await avatarViewModel.loadGLB(named: glbAsset)
        }
        Task { await client.prewarm() }
    }

    func sendText(_ text: String) async {
        guard !isStreaming, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        if isOffline {
            errorMessage = "You're offline. Chat requires an internet connection."
            return
        }
        if !hasApiKey {
            errorMessage = "Add an API key in Settings to start chatting."
            return
        }

        cancelStream()
        errorMessage = nil
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        messages.append(ChatMessage(role: "user", text: trimmed))

        isStreaming = true
        avatarViewModel.setThinking(true)

        // Run independent DB operations concurrently before the streaming task
        async let turnIdTask = (try? store.insertTurn(companionId: companion.id, role: "user", text: trimmed)) ?? 0
        async let stageTask = (try? store.relationshipStage(companionId: companion.id)) ?? "acquaintance"
        async let memoriesTask = (try? store.salientMemories(userId: userId, companionId: companion.id)) ?? []
        let (turnId, stage, memories) = await (turnIdTask, stageTask, memoriesTask)

        messages.append(ChatMessage(role: "assistant", text: ""))
        let msgIndex = messages.count - 1

        let systemPrompt = PersonaAssembler.systemPrompt(
            companionName: companion.name,
            traits: companion.traits,
            memories: memories,
            appearance: companion.appearance,
            stage: stage
        )

        streamTask = Task {
            var fullReply = ""

            for candidate in chatCandidates {
                guard isStreaming else { break }
                do {
                    let chatMessages = buildChatMessages(system: systemPrompt, history: messages, newUserText: trimmed)
                    var streamed = ""
                    for try await delta in await client.streamChat(model: candidate.id, messages: chatMessages) {
                        try Task.checkCancellation()
                        streamed += delta
                        fullReply += delta
                        messages[msgIndex].text = streamed
                    }
                    break
                } catch is CancellationError {
                    return
                } catch {
                    errorMessage = "\(candidate.id) failed: \(error.localizedDescription)"
                    continue
                }
            }

            isStreaming = false
            avatarViewModel.setThinking(false)

            guard !fullReply.trimmingCharacters(in: .whitespaces).isEmpty else {
                if chatCandidates.isEmpty {
                    messages[msgIndex].text = "⚠️ No models available. Refresh the model catalog in Settings."
                } else {
                    messages[msgIndex].text = "⚠️ All models failed. Check your API key or the model catalog."
                }
                return
            }

            _ = (try? await store.insertTurn(companionId: companion.id, role: "assistant", text: fullReply)) ?? 0

            let catalog = (await catalogCache.load())?.entries ?? []
            Task {
                try? await extractor.extractAndStore(
                    userId: userId, companionId: companion.id, turnId: turnId,
                    userText: trimmed, assistantText: fullReply, catalog: catalog
                )
            }
            await checkStagePromotion(liveTurnCount: (try? await store.liveTurnCount(companionId: companion.id)) ?? 0)
            if hasAppearanceIntent(text: trimmed) {
                await handleAppearanceIntent(userText: trimmed, catalog: catalog)
            }
            let (cleanText, track) = PerformanceTrackParser.extract(from: fullReply)
            messages[msgIndex].text = cleanText
            speakReply(cleanText, track: track)
        }
    }

    func cancelStream() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
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
            avatarViewModel.setListening(true)
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
        avatarViewModel.setListening(false)
        if !pendingTranscript.trimmingCharacters(in: .whitespaces).isEmpty {
            let text = pendingTranscript
            pendingTranscript = ""
            Task { await sendText(text) }
        }
    }

    private func speakReply(_ text: String, track: PerformanceTrack? = nil) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        let voiceId = companion.voiceId ?? VoicePicker.selectVoice()
        var hasStarted = false

        ttsEngine.speak(
            text,
            voiceId: voiceId,
            pitch: 1.0,
            rate: 0.5,
            rangeCallback: { [weak self] nsRange in
                guard let self else { return }
                if !hasStarted {
                    hasStarted = true
                    self.avatarViewModel.beginSpeaking(text: text, track: track)
                    self.isSpeaking = true
                }
                self.avatarViewModel.updateSpeechRange(characterRange: nsRange, text: text)
            },
            energiesCallback: { [weak self] energies, duration in
                self?.avatarViewModel.setPCMEnergies(energies, duration: duration)
            },
            completion: { [weak self] in
                Task { @MainActor in
                    self?.isSpeaking = false
                    self?.avatarViewModel.endSpeaking()
                }
            }
        )
    }

    func cachedImageData(companionId: Int64) async -> Data? {
        await imageGenService.cachedImageData(companionId: companionId)
    }

    func stopSpeaking() {
        ttsEngine.stop()
        isSpeaking = false
        avatarViewModel.endSpeaking()
    }

    private func hasAppearanceIntent(text: String) -> Bool {
        let lower = text.lowercased()
        return intentPatterns.contains { lower.contains($0) }
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
            avatarViewModel.applyAppearance(companion.appearance)
            appearanceVersion += 1

            let confirmMsg = ChatMessage(role: "assistant", text: "Got it! Changing \(result.attribute) to \(value).")
            messages.append(confirmMsg)
            avatarViewModel.beginSpeaking(text: confirmMsg.text, track: nil)
            speakReply(confirmMsg.text)
        } else if let suggestion = result.suggestion {
            let imageGenOn = UserDefaults.standard.bool(forKey: "image_gen_enabled")
            if imageGenOn, let attribute = delta.value {
                let genMsg = ChatMessage(role: "assistant", text: "Generating a reference image for your requested look...")
                messages.append(genMsg)

                let prompt = "Portrait of a person with \(delta.attribute) set to \(attribute), consistent with current appearance: \(companion.appearance.map { "\($0.0): \($0.1)" }.joined(separator: ", "))"
                let existingData = await imageGenService.cachedImageData(companionId: companion.id)
                if let _ = try? await imageGenService.generateForCompanion(
                    companionId: companion.id, prompt: prompt, catalog: catalog, referenceData: existingData
                ) {
                    if let newImg = await imageGenService.cachedImageData(companionId: companion.id) {
                        avatarViewModel.applyReferenceImage(newImg)
                    }
                    let doneMsg = ChatMessage(role: "assistant", text: "Reference image generated and applied to your companion.")
                    messages.append(doneMsg)
                    avatarViewModel.applyAppearance(companion.appearance)
                    appearanceVersion += 1
                }
            } else {
                let declineMsg = ChatMessage(role: "assistant", text: suggestion)
                messages.append(declineMsg)
                avatarViewModel.beginSpeaking(text: declineMsg.text, track: nil)
                speakReply(declineMsg.text)
            }
        }
    }

    private func loadApiKey() async {
        if let key = await keychain.read(key: KeychainService.apiKeyAccount), !key.isEmpty {
            await client.setKey(key)
            hasApiKey = true
        } else {
            hasApiKey = false
        }
    }

    private func loadChatCandidates() async {
        if let cached = await catalogCache.load() {
            chatCandidates = SelectionPolicy(role: .chat, catalog: cached.entries, pinnedModelId: nil).rank()
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

    private func checkStagePromotion(liveTurnCount: Int) async {
        let stageThresholds: [(String, Int)] = [
            ("acquaintance", 5),
            ("friend", 20),
        ]
        let currentStage = (try? await store.relationshipStage(companionId: companion.id)) ?? "acquaintance"
        for (stage, threshold) in stageThresholds {
            if currentStage == stage, liveTurnCount >= threshold {
                try? await store.promoteStage(companionId: companion.id)
                let newStage = (try? await store.relationshipStage(companionId: companion.id)) ?? stage
                avatarViewModel.setStage(newStage)
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    var text: String
}
