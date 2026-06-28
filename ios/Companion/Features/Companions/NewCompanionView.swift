import SwiftUI

struct NewCompanionView: View {
    @Environment(\.dismiss) private var dismiss
    let onCreated: (Int64) -> Void

    @State private var name = ""
    @State private var selectedTraits: [String] = ["friendly"]
    @State private var hairColor = "brown"
    @State private var eyeColor = "blue"
    @State private var skinTone = "light"

    private let store = MemoryStore()
    private let traitOptions = ["friendly", "curious", "witty", "calm", "energetic", "thoughtful", "playful", "wise"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Companion name", text: $name)
                }
                Section("Traits") {
                    ForEach(traitOptions, id: \.self) { trait in
                        Button {
                            toggleTrait(trait)
                        } label: {
                            HStack {
                                Text(trait.capitalized)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedTraits.contains(trait) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                Section("Appearance") {
                    Picker("Hair Color", selection: $hairColor) {
                        ForEach(["brown", "black", "blonde", "red", "gray"], id: \.self) { c in
                            Text(c.capitalized).tag(c)
                        }
                    }
                    Picker("Eye Color", selection: $eyeColor) {
                        ForEach(["blue", "brown", "green", "hazel", "gray"], id: \.self) { c in
                            Text(c.capitalized).tag(c)
                        }
                    }
                    Picker("Skin Tone", selection: $skinTone) {
                        ForEach(["light", "medium", "dark", "tan", "pale"], id: \.self) { c in
                            Text(c.capitalized).tag(c)
                        }
                    }
                }
            }
            .navigationTitle("New Companion")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await create() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func toggleTrait(_ trait: String) {
        if let idx = selectedTraits.firstIndex(of: trait) {
            selectedTraits.remove(at: idx)
        } else {
            selectedTraits.append(trait)
        }
    }

    private func create() async {
        let userId = (try? await store.ensureUser()) ?? 1
        let traits = selectedTraits.map { ($0, 0.8) }
        let appearance: [(String, String)] = [
            ("hair_color", hairColor),
            ("eye_color", eyeColor),
            ("skin_tone", skinTone)
        ]
        let companionId = (try? await store.createCompanion(
            userId: userId,
            name: name.trimmingCharacters(in: .whitespaces),
            traits: traits,
            appearance: appearance
        )) ?? 0
        onCreated(companionId)
        dismiss()
    }
}
