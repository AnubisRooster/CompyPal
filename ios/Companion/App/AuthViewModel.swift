import SwiftUI
import AuthenticationServices

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isBackendHealthy = false
    @Published var userName: String?

    private let apiClient = APIClient()

    func handleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                userName = appleIDCredential.fullName?.givenName ?? "User"
                isAuthenticated = true
                checkBackendHealth()
            }
        case .failure(let error):
            print("Sign in failed: \(error.localizedDescription)")
        }
    }

    func signOut() {
        isAuthenticated = false
        isBackendHealthy = false
        userName = nil
    }

    func checkBackendHealth() {
        Task {
            let healthy = try? await apiClient.healthCheck()
            isBackendHealthy = healthy ?? false
        }
    }
}
