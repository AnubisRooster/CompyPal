import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            if authViewModel.isAuthenticated {
                connectionStatus
            } else {
                signInView
            }
        }
        .padding()
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
    }

    private var connectionStatus: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Connected")
                .font(.title)
                .bold()

            if authViewModel.isBackendHealthy {
                Label("Backend reachable", systemImage: "checkmark")
                    .foregroundStyle(.green)
            } else {
                ProgressView("Checking backend...")
            }

            Button("Sign Out") {
                authViewModel.signOut()
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
