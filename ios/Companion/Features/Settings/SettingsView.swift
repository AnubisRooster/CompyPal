import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey = ""
    @State private var savedKey: String?
    @State private var statusMessage: String?
    @State private var showAlert = false
    @State private var isFirstLaunch = false

    @AppStorage("image_gen_enabled") private var imageGenEnabled = false
    @AppStorage("tts_rate") private var ttsRate: Double = 0.5
    @AppStorage("has_onboarded") private var hasOnboarded = false
    @AppStorage("pinned_model_id") private var pinnedModelId = ""
    @AppStorage("cloud_voice_enabled") private var cloudVoiceEnabled = false
    @AppStorage("eleven_voice_id") private var elevenVoiceId = ElevenLabsTTS.defaultVoiceId

    @State private var catalogEntries: [CatalogEntry] = []
    @State private var catalogStatus: String?
    @State private var isRefreshing = false

    @State private var elevenKey = ""
    @State private var elevenKeySaved = false
    @State private var elevenStatus: String?
    @State private var elevenVoices: [ElevenLabsTTS.Voice] = []
    @State private var isLoadingVoices = false

    private let keychain = KeychainService()
    private let catalogCache = CatalogCache()
    private let catalogFetcher = CatalogFetcher()

    private var chatModels: [CatalogEntry] {
        SelectionPolicy(role: .chat, catalog: catalogEntries, pinnedModelId: nil).rank()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("OpenRouter API Key") {
                    SecureField("sk-or-v1-...", text: $apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .onAppear { loadKey() }

                    if let saved = savedKey, !saved.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Key is configured")
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }

                    Button("Save Key") {
                        saveKey()
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)

                    if let msg = statusMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Model") {
                    if isRefreshing {
                        HStack {
                            ProgressView()
                            Text("Refreshing models…").foregroundColor(.secondary)
                        }
                    } else {
                        Button("Refresh Models") {
                            Task { await refreshCatalog() }
                        }
                        .disabled(savedKey?.isEmpty ?? true)
                    }

                    if !chatModels.isEmpty {
                        Picker("Selected Model", selection: $pinnedModelId) {
                            Text("Auto (cost-first)").tag("")
                            ForEach(chatModels, id: \.id) { model in
                                Text(model.name ?? model.id).tag(model.id)
                            }
                        }
                    }

                    if let status = catalogStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if chatModels.isEmpty {
                        Text("No models loaded yet. Tap Refresh Models.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("TTS Speed") {
                    VStack(alignment: .leading) {
                        Slider(value: $ttsRate, in: 0.25...1.0, step: 0.05) {
                            Text("Speech Rate")
                        } minimumValueLabel: {
                            Text("Slow").font(.caption)
                        } maximumValueLabel: {
                            Text("Fast").font(.caption)
                        }
                        Text("\(Int(ttsRate * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                    }
                    .accessibilityLabel("Speech rate")
                    .accessibilityValue("\(Int(ttsRate * 100)) percent")
                }

                Section {
                    Toggle("Use Realistic Voice (ElevenLabs)", isOn: $cloudVoiceEnabled)

                    SecureField("ElevenLabs API key", text: $elevenKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()

                    if elevenKeySaved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text("ElevenLabs key configured").foregroundColor(.secondary)
                        }
                    }

                    Button("Save Voice Key") { saveElevenKey() }
                        .disabled(elevenKey.trimmingCharacters(in: .whitespaces).isEmpty)

                    if isLoadingVoices {
                        HStack { ProgressView(); Text("Loading voices…").foregroundColor(.secondary) }
                    } else {
                        Button("Load Voices") { Task { await loadElevenVoices() } }
                            .disabled(!elevenKeySaved)
                    }

                    if !elevenVoices.isEmpty {
                        Picker("Voice", selection: $elevenVoiceId) {
                            ForEach(elevenVoices) { voice in
                                Text(voice.name).tag(voice.id)
                            }
                        }
                    }

                    if let status = elevenStatus {
                        Text(status).font(.caption).foregroundColor(.secondary)
                    }
                } header: {
                    Text("Realistic Voice")
                } footer: {
                    Text("A neural voice that sounds far more lifelike than the built-in one. Requires an ElevenLabs API key and uses your ElevenLabs quota. When off (or offline), the on-device voice is used.")
                }

                Section("Image Generation") {
                    Toggle("Enable Image Generation", isOn: $imageGenEnabled)
                }

                Section("Memory") {
                    Button("Clear All Memories", role: .destructive) {
                        showAlert = true
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .task { await loadCachedCatalog() }
            .alert("Clear Memory", isPresented: $showAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    Task {
                        let store = MemoryStore()
                        try? await store.clearAll()
                    }
                }
            } message: {
                Text("This will delete all companion memories and conversation history. This cannot be undone.")
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            if !hasOnboarded {
                isFirstLaunch = true
                hasOnboarded = true
            }
        }
        .sheet(isPresented: $isFirstLaunch) {
            OnboardingView()
        }
    }

    private func loadKey() {
        do {
            let key = try keychain.read(key: KeychainService.apiKeyAccount)
            guard !key.isEmpty else { return }
            savedKey = key
            apiKey = key
            statusMessage = "Key loaded from secure storage."
        } catch {
            statusMessage = "Could not read key: \(error)"
        }
    }

    private func saveKey() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespaces)
        guard KeychainService.isValidKey(trimmed) else {
            statusMessage = "Invalid key format. OpenRouter keys start with 'sk-or-' and are at least 20 characters."
            return
        }
        do {
            try keychain.store(key: KeychainService.apiKeyAccount, value: trimmed)
            savedKey = trimmed
            statusMessage = "Key saved securely."
            // Populate the model catalog now that we have a key, so the user can
            // chat immediately instead of hitting "No models available".
            Task { await refreshCatalog() }
        } catch {
            statusMessage = "Failed to save key: \(error.localizedDescription)"
        }
    }

    private func loadCachedCatalog() async {
        if let cached = await catalogCache.load(), !cached.entries.isEmpty {
            catalogEntries = cached.entries
        }
        if let key = try? await keychain.read(key: ElevenLabsTTS.keychainAccount), !key.isEmpty {
            elevenKey = key
            elevenKeySaved = true
        }
    }

    private func saveElevenKey() {
        let trimmed = elevenKey.trimmingCharacters(in: .whitespaces)
        guard ElevenLabsTTS.isValidKey(trimmed) else {
            elevenStatus = "That doesn't look like a valid ElevenLabs key."
            return
        }
        Task {
            do {
                try await keychain.store(key: ElevenLabsTTS.keychainAccount, value: trimmed)
                elevenKeySaved = true
                elevenStatus = "Voice key saved securely."
                await loadElevenVoices()
            } catch {
                elevenStatus = "Failed to save key: \(error.localizedDescription)"
            }
        }
    }

    private func loadElevenVoices() async {
        let key = elevenKey.trimmingCharacters(in: .whitespaces)
        guard ElevenLabsTTS.isValidKey(key) else { return }
        isLoadingVoices = true
        defer { isLoadingVoices = false }
        do {
            let voices = try await ElevenLabsTTS.fetchVoices(apiKey: key)
            elevenVoices = voices
            if !voices.contains(where: { $0.id == elevenVoiceId }), let first = voices.first {
                elevenVoiceId = first.id
            }
            elevenStatus = "Loaded \(voices.count) voices."
        } catch {
            elevenStatus = "Could not load voices: \(error.localizedDescription)"
        }
    }

    private func refreshCatalog() async {
        guard let key = try? await keychain.read(key: KeychainService.apiKeyAccount), !key.isEmpty else {
            catalogStatus = "Add and save an API key first."
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let entries = try await catalogFetcher.fetch(apiKey: key)
            try await catalogCache.save(entries: entries)
            catalogEntries = entries
            catalogStatus = "Loaded \(entries.count) models."
        } catch {
            catalogStatus = "Refresh failed: \(error.localizedDescription)"
        }
    }
}

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Welcome to Companion")
                    .font(.title).bold()
                Text("Your AI companion lives entirely on-device. All chats, memories, and personalization are stored locally.\n\nTo start, add your OpenRouter API key in Settings. Your key stays in the iOS Keychain — it never leaves your device.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Get Started") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Onboarding")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
