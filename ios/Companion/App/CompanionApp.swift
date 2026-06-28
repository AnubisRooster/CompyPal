import SwiftUI

@main
struct CompanionApp: App {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var catalogChecker = CatalogRefreshChecker()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await catalogChecker.refreshIfStale()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task {
                        await catalogChecker.refreshIfStale()
                    }
                }
        }
    }
}

@MainActor
private class CatalogRefreshChecker {
    private let cache = CatalogCache()
    private let fetcher = CatalogFetcher()
    private let keychain = KeychainService()

    func refreshIfStale() async {
        guard await cache.isStale() else { return }
        guard let key = await keychain.read(key: KeychainService.apiKeyAccount), !key.isEmpty else { return }
        do {
            let entries = try await fetcher.fetch(apiKey: key)
            try await cache.save(entries: entries)
        } catch {}
    }
}
