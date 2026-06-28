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
