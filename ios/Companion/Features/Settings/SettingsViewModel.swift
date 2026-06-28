import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var connectionStatus: ConnectionStatus = .idle
    @Published var chatMode: ModelMode = .auto
    @Published var catalogStatus: CatalogStatus = .unknown
    @Published var imageGenEnabled: Bool {
        didSet { UserDefaults.standard.set(imageGenEnabled, forKey: "image_gen_enabled") }
    }

    private let keychain = KeychainService()
    private let catalogFetcher = CatalogFetcher()
    private let catalogCache = CatalogCache()
    private let client = OpenRouterClient()

    init() {
        imageGenEnabled = UserDefaults.standard.bool(forKey: "image_gen_enabled")
    }

    enum ConnectionStatus: Equatable {
        case idle, testing, success(String), failed(String)
    }

    enum ModelMode: String, CaseIterable {
        case auto = "Auto (Recommended)"
        case pinned = "Pinned Model"
    }

    enum CatalogStatus: Equatable {
        case unknown, cached(Date), refreshing, fetched(Int), failed(String)
    }

    func loadKey() async {
        let key = await keychain.read(key: KeychainService.apiKeyAccount) ?? ""
        apiKey = key
        if !key.isEmpty {
            await client.setKey(key)
        }
    }

    func saveKey() async {
        guard !apiKey.isEmpty else { return }
        try? await keychain.store(key: KeychainService.apiKeyAccount, value: apiKey)
        await client.setKey(apiKey)
    }

    func testConnection() async {
        connectionStatus = .testing
        do {
            let key = await keychain.read(key: KeychainService.apiKeyAccount) ?? ""
            guard !key.isEmpty else { throw ClientError.noKey }
            await client.setKey(key)

            guard let cached = await catalogCache.load(), !cached.entries.isEmpty else {
                connectionStatus = .failed("No cached model catalog. Refresh models first.")
                return
            }
            let policy = SelectionPolicy(role: .chat, catalog: cached.entries, pinnedModelId: nil)
            guard let model = policy.best() else {
                connectionStatus = .failed("No suitable chat model found in catalog.")
                return
            }
            let reply = try await client.testConnection(model: model.id)
            connectionStatus = .success(reply)
        } catch {
            connectionStatus = .failed(error.localizedDescription)
        }
    }

    func refreshCatalog() async {
        catalogStatus = .refreshing
        guard let key = await keychain.read(key: KeychainService.apiKeyAccount), !key.isEmpty else {
            catalogStatus = .failed("No API key")
            return
        }
        do {
            let entries = try await catalogFetcher.fetch(apiKey: key)
            try await catalogCache.save(entries: entries)
            catalogStatus = .fetched(entries.count)
        } catch {
            catalogStatus = .failed(error.localizedDescription)
        }
    }

    func loadCatalogStatus() async {
        if let cached = await catalogCache.load() {
            catalogStatus = .cached(cached.lastRefreshed)
        }
    }

    func deleteKey() async {
        await keychain.delete(key: KeychainService.apiKeyAccount)
        apiKey = ""
        connectionStatus = .idle
    }
}
