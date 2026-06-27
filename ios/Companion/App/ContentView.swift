import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ChatPlaceholderView()
                    .navigationTitle("Companion")
            }
            .tabItem { Label("Chat", systemImage: "message.fill") }

            NavigationStack {
                CompanionListView()
                    .navigationTitle("Companions")
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
            Text("Add an API key in Settings")
                .foregroundStyle(.secondary)
            Text("then create a companion to start chatting.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

struct CompanionListView: View {
    var body: some View {
        ContentUnavailableView(
            "No Companions",
            systemImage: "person.slash",
            description: Text("Create a companion to get started.")
        )
    }
}

#Preview { ContentView() }
