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

    private var skinColor: Color {
        colorValue(for: "skin_tone") ?? Color(red: 0.85, green: 0.65, blue: 0.5)
    }

    private var hairColor: Color {
        colorValue(for: "hair_color") ?? Color(red: 0.4, green: 0.25, blue: 0.15)
    }

    private var eyeColor: Color {
        colorValue(for: "eye_color") ?? Color(red: 0.25, green: 0.45, blue: 0.8)
    }

    private var hairLength: String {
        let map = Dictionary(uniqueKeysWithValues: appearance.map { ($0.0, $0.1) })
        return map["hair_length"] ?? "medium"
    }

    private var hairStyle: String {
        let map = Dictionary(uniqueKeysWithValues: appearance.map { ($0.0, $0.1) })
        return map["hair_style"] ?? "straight"
    }

    private var isLong: Bool { hairLength == "long" }

    var body: some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
            } else {
                renderedFace
            }
        }
        .task {
            let imageGenService = ImageGenerationService(client: OpenRouterClient())
            imageData = await imageGenService.cachedImageData(companionId: companionId)
        }
    }

    @ViewBuilder
    private var renderedFace: some View {
        ZStack {
            // Hair (background layer)
            if isLong {
                HairShape(style: hairStyle)
                    .fill(hairColor)
                    .offset(y: -2)
            }

            // Head
            Circle()
                .fill(skinColor)

            // Hair (short/medium on top)
            if !isLong {
                HairShape(style: hairStyle)
                    .fill(hairColor)
                    .mask(Circle().offset(y: -8))
            }

            // Eyes
            HStack(spacing: 10) {
                Circle().fill(.white).frame(width: 6, height: 6)
                    .overlay(Circle().fill(eyeColor).frame(width: 3, height: 3))
                Circle().fill(.white).frame(width: 6, height: 6)
                    .overlay(Circle().fill(eyeColor).frame(width: 3, height: 3))
            }
            .offset(y: -1)

            // Mouth
            Capsule()
                .fill(Color(red: 0.6, green: 0.3, blue: 0.2))
                .frame(width: 8, height: 2)
                .offset(y: 5)
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
    }

    private func colorValue(for key: String) -> Color? {
        guard let value = Dictionary(uniqueKeysWithValues: appearance.map { ($0.0, $0.1) })[key] else { return nil }
        return ParametricSchema.shared.color(for: key, value: value).map { Color($0) }
    }
}

private struct HairShape: Shape {
    let style: String

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch style {
        case "wavy":
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY - 2), radius: rect.width * 0.55,
                       startAngle: .degrees(10), endAngle: .degrees(170), clockwise: false)
            path.addLine(to: CGPoint(x: rect.width * 0.85, y: rect.midY + rect.height * 0.3))
            for i in stride(from: 0, to: 10, by: 1) {
                let x = rect.width * 0.85 - rect.width * 0.17 * CGFloat(i / 10)
                let y = rect.midY + rect.height * 0.3 + sin(CGFloat(i) * 0.8) * 4
                path.addLine(to: CGPoint(x: x, y: y))
            }
        case "curly":
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY - 4), radius: rect.width * 0.6,
                       startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            addCurlyBumps(to: &path, rect: rect)
        default:
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY - 4), radius: rect.width * 0.55,
                       startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        }
        return path
    }

    private func addCurlyBumps(to path: inout Path, rect: CGRect) {
        for i in 0..<6 {
            let x = rect.minX + rect.width * CGFloat(i) / 5
            let y = rect.midY - 6 + sin(CGFloat(i) * 1.5) * 5
            path.addEllipse(in: CGRect(x: x - 3, y: y - 3, width: 6, height: 6))
        }
    }
}
