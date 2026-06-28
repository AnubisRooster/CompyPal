import SwiftUI

struct CompanionsView: View {
    @StateObject private var viewModel = CompanionsViewModel()
    @State private var showSettings = false
    @State private var showNewCompanion = false
    @State private var selectedCompanion: CompanionInfo?
    let onCompanionSelected: ((CompanionInfo) -> Void)?

    init(onCompanionSelected: ((CompanionInfo) -> Void)? = nil) {
        self.onCompanionSelected = onCompanionSelected
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isOffline {
                    ContentUnavailableView(
                        "Offline",
                        systemImage: "wifi.slash",
                        description: Text("Select a companion from earlier sessions.")
                    )
                } else if viewModel.companions.isEmpty {
                    ContentUnavailableView(
                        "No Companions",
                        systemImage: "person.3",
                        description: Text("Tap + to create your first companion.")
                    )
                } else {
                    List {
                        ForEach(viewModel.companions) { companion in
                            Button {
                                selectedCompanion = companion
                                onCompanionSelected?(companion)
                            } label: {
                                CompanionRow(companion: companion)
                            }
                            .accessibilityLabel("Companion: \(companion.name)")
                        }
                        .onDelete { indexSet in
                            Task { await viewModel.delete(at: indexSet) }
                        }
                    }
                }
            }
            .navigationTitle("Companions")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gear") {
                        showSettings = true
                    }
                    .accessibilityLabel("Open settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.isOffline {
                        Button("New", systemImage: "plus") {
                            showNewCompanion = true
                        }
                        .accessibilityLabel("Create a new companion")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showNewCompanion) {
                NewCompanionView { _ in
                    Task { await viewModel.loadCompanions() }
                }
            }
            .navigationDestination(item: $selectedCompanion) { companion in
                ChatView(companion: companion)
            }
            .task { await viewModel.loadCompanions() }
            .onReceive(NetworkMonitor.shared.$isConnected) { connected in
                viewModel.isOffline = !connected
            }
        }
    }
}

struct CompanionRow: View {
    let companion: CompanionInfo

    var body: some View {
        HStack(spacing: 12) {
            AvatarThumbnail(companionId: companion.id, appearance: companion.appearance)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(companion.name)
                    .font(.headline)
                Text(companion.traits.prefix(3).map(\.0).joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Label("Level \(companion.level)", systemImage: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(companion.relationshipStage.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AvatarThumbnail: View {
    let companionId: Int64
    let appearance: [(String, String)]
    @State private var imageData: Data?

    var body: some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                    }
            }
        }
        .task {
            let imageGenService = ImageGenerationService(client: OpenRouterClient())
            imageData = await imageGenService.cachedImageData(companionId: companionId)
        }
    }
}
