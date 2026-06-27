import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                mainTabView
            } else {
                signInView
            }
        }
    }

    private var mainTabView: some View {
        TabView {
            NavigationStack {
                ChatView(companionId: "default-companion", userId: authViewModel.userName ?? "user")
                    .navigationTitle("Companion")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Sign Out") { authViewModel.signOut() }
                        }
                    }
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

    private var signInView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("AI Companion")
                .font(.largeTitle)
                .bold()

            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    authViewModel.handleSignIn(result: result)
                }
            )
            .frame(height: 50)
            .clipShape(.rect(cornerRadius: 12))
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

struct CompanionListView: View {
    @State private var companions: [CompanionState] = []
    @State private var showingCreate = false

    var body: some View {
        List(companions, id: \.companionId) { comp in
            NavigationLink(comp.name, value: comp)
        }
        .navigationDestination(for: CompanionState.self) { comp in
            ChatView(companionId: comp.companionId, userId: "user")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("New", systemImage: "plus") { showingCreate = true }
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateCompanionView()
        }
    }
}

struct SettingsView: View {
    var body: some View {
        List {
            Section("Connection") {
                Label("Backend: localhost:8000", systemImage: "network")
            }
            Section("About") {
                Label("Version 0.1.0", systemImage: "info.circle")
            }
        }
    }
}

struct CreateCompanionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
            }
            .navigationTitle("New Companion")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Create") { dismiss() } }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
