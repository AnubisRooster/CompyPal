import SwiftUI

@MainActor
class CompanionsViewModel: ObservableObject {
    @Published var companions: [CompanionInfo] = []
    @Published var showCreate = false
    @Published var newName = ""
    @Published var newTraits = [("friendly", 0.8), ("curious", 0.7)]
    @Published var isOffline = false

    private let store = MemoryStore()
    private var userId: Int64 = 1

    func loadCompanions() async {
        userId = (try? await store.ensureUser()) ?? 1
        try? await store.ensureSeedCompanions(userId: userId)
        companions = (try? await store.companions(userId: userId)) ?? []
        isOffline = !NetworkMonitor.shared.isConnected
    }

    func create() async {
        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        _ = try? await store.createCompanion(
            userId: userId,
            name: newName.trimmingCharacters(in: .whitespaces),
            traits: newTraits,
            appearance: [("hair_color", "brown"), ("eye_color", "blue"), ("skin_tone", "light")]
        )
        newName = ""
        await loadCompanions()
        showCreate = false
    }

    func delete(at indexSet: IndexSet) async {
        for index in indexSet {
            let id = companions[index].id
            let queue = try? await DatabaseManager.shared.open()
            try? await queue?.write { db in
                try db.execute(sql: "DELETE FROM companion WHERE id = ?", arguments: [id])
            }
        }
        await loadCompanions()
    }
}
