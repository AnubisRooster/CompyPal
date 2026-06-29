import SwiftUI

struct ContentView: View {
    @State private var recentCompanion: CompanionInfo?

    var body: some View {
        TabView {
            NavigationStack {
                if let companion = recentCompanion {
                    ChatView(companion: companion)
                } else {
                    ChatPlaceholderView()
                        .navigationTitle("Companion")
                }
            }
            .tabItem { Label("Chat", systemImage: "message.fill") }

            NavigationStack {
                CompanionsView(onCompanionSelected: { companion in
                    recentCompanion = companion
                })
            }
            .tabItem { Label("Companions", systemImage: "person.2.fill") }

            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem { Label("Settings", systemImage: "gear") }
        }
        .task {
            await loadDefaultCompanion()
        }
    }

    /// Picks a default companion to show on the Chat tab at launch.
    /// Prefers Riven (the canonical 3D-avatar companion), falls back to first available.
    /// Retries briefly to handle the race where seeding hasn't finished writing yet
    /// on a cold launch with a fresh database.
    private func loadDefaultCompanion() async {
        guard recentCompanion == nil else { return }
        let store = MemoryStore()
        guard let userId = try? await store.ensureUser() else { return }

        // Seeding runs concurrently in CompanionApp; poll for up to ~3s so a cold
        // launch with a fresh database still resolves a default companion.
        for _ in 0..<15 {
            if let companions = try? await store.companions(userId: userId), !companions.isEmpty {
                recentCompanion = companions.first(where: { $0.name == "Riven" }) ?? companions.first
                return
            }
            try? await Task.sleep(for: .milliseconds(200))
        }
    }
}

struct ChatPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "character.bubble.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Select a companion to start chatting")
                .foregroundStyle(.secondary)
        }
    }
}
