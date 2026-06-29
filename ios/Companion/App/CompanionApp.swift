import SwiftUI
import OSLog

private let appLog = Logger(subsystem: "ai.companion", category: "app")

@main
struct CompanionApp: App {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var catalogChecker = CatalogRefreshChecker()
    @State private var seedTask: Task<Void, Never>?

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Seed companions independently of the network catalog refresh.
                // Gating seeding behind refreshIfStale() (request timeout up to 15s)
                // could leave the DB unseeded past ContentView's ~1s default-companion
                // retry window, so Riven/Atlas wouldn't appear on the Chat tab at launch.
                .task {
                    await seedCompanionsAtLaunch()
                }
                .task {
                    await catalogChecker.refreshIfStale()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task {
                        await catalogChecker.refreshIfStale()
                        await warmConnectionOnForeground()
                    }
                }
        }
    }

    private func warmConnectionOnForeground() async {
        let keychain = KeychainService()
        guard let key = try? await keychain.read(key: KeychainService.apiKeyAccount), !key.isEmpty else { return }
        let client = OpenRouterClient()
        await client.setKey(key)
        await client.prewarm()
    }

    private func seedCompanionsAtLaunch() async {
        let store = MemoryStore()
        guard let userId = try? await store.ensureUser() else {
            appLog.warning("Could not ensure user for seed companions")
            return
        }
        do {
            try await store.ensureSeedCompanions(userId: userId)
            appLog.info("Seed companions check complete for userId=\(userId)")
        } catch {
            appLog.error("Seed companions failed: \(error.localizedDescription)")
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
        guard let key = try? await keychain.read(key: KeychainService.apiKeyAccount), !key.isEmpty else { return }
        do {
            let entries = try await fetcher.fetch(apiKey: key)
            try await cache.save(entries: entries)
        } catch {}
    }
}
