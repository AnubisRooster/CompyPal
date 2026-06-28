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

    private let keychain = KeychainService()

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
        } catch {
            statusMessage = "Failed to save key: \(error.localizedDescription)"
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
