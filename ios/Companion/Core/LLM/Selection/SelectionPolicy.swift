import Foundation

struct SelectionPolicy {
    let role: ModelRole
    let catalog: [CatalogEntry]
    let pinnedModelId: String?

    func rank() -> [CatalogEntry] {
        let filtered = catalog.filter { meetsRequirements($0, for: role) }
        let sorted = filtered.sorted { a, b in
            let aFree = isFree(a)
            let bFree = isFree(b)
            if aFree != bFree { return aFree }
            return totalCost(a) < totalCost(b)
        }
        if let pinned = pinnedModelId, let match = catalog.first(where: { $0.id == pinned }) {
            return [match] + sorted.filter { $0.id != pinned }
        }
        return sorted
    }

    func best() -> CatalogEntry? { rank().first }

    private func meetsRequirements(_ entry: CatalogEntry, for role: ModelRole) -> Bool {
        switch role {
        case .chat:
            return entry.modalities?.output?.contains("text") ?? false
        case .extract:
            return entry.supportedParameters?.contains("tools") ?? false
        case .image:
            return entry.modalities?.output?.contains("image") ?? false
        }
    }

    private func isFree(_ entry: CatalogEntry) -> Bool {
        entry.pricing.prompt == 0 && entry.pricing.completion == 0
    }

    private func totalCost(_ entry: CatalogEntry) -> Double {
        entry.pricing.prompt + entry.pricing.completion + (entry.pricing.image ?? 0)
    }
}
