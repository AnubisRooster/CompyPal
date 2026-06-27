import Foundation

actor AppearanceApplier {
    private let store: MemoryStore

    init(store: MemoryStore) {
        self.store = store
    }

    func apply(delta: AppearanceDelta, companionId: Int64) async throws -> AppearanceDelta {
        let validated = ParametricSchema.shared.validate(delta: delta)
        guard let value = validated.value, validated.declined != true else {
            return validated
        }
        try await store.updateAppearance(companionId: companionId, key: validated.attribute, value: value)
        return validated
    }
}
