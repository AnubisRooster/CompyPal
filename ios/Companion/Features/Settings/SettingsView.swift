import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showConfirmation = false
    @State private var savedKey = false

    var body: some View {
        Form {
            Section("OpenRouter API Key") {
                SecureField("Enter your API key", text: $viewModel.apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()

                if savedKey {
                    Text("Key saved to Keychain")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                Button("Save to Keychain") {
                    Task { await viewModel.saveKey(); savedKey = true }
                }
                .disabled(viewModel.apiKey.isEmpty)
            }

            Section("Connection") {
                switch viewModel.connectionStatus {
                case .idle:
                    Button("Test Connection") {
                        Task { await viewModel.testConnection() }
                    }
                case .testing:
                    HStack { ProgressView(); Text("Testing...") }
                case .success(let reply):
                    Label("OK: \(reply)", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .failed(let msg):
                    Label(msg, systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }

            Section("Model Catalog") {
                switch viewModel.catalogStatus {
                case .unknown:
                    Button("Fetch Models") {
                        Task { await viewModel.refreshCatalog() }
                    }
                case .cached(let date):
                    Label("Cached: \(date.formatted())", systemImage: "clock")
                    Button("Refresh") {
                        Task { await viewModel.refreshCatalog() }
                    }
                case .refreshing:
                    HStack { ProgressView(); Text("Refreshing...") }
                case .fetched(let count):
                    Label("\(count) models", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .failed(let msg):
                    Label(msg, systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Button("Retry") {
                        Task { await viewModel.refreshCatalog() }
                    }
                }

                Button("Refresh Models") {
                    Task { await viewModel.refreshCatalog() }
                }
            }

            Section("Model Selection") {
                Picker("Chat Model", selection: $viewModel.chatMode) {
                    ForEach(SettingsViewModel.ModelMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            }

            Section("Experimental") {
                Toggle("Image Generation", isOn: $viewModel.imageGenEnabled)
                Text("When enabled, the companion can generate a reference image for appearance changes outside the parametric space. Uses a paid image model. Disabled by default.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Danger Zone") {
                Button("Delete API Key", role: .destructive) {
                    showConfirmation = true
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Delete API Key?", isPresented: $showConfirmation) {
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteKey() }
            }
        }
        .task {
            await viewModel.loadKey()
            await viewModel.loadCatalogStatus()
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
