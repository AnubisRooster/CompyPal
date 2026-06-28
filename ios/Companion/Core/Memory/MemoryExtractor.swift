import Foundation

actor MemoryExtractor {
    private let client: OpenRouterClient
    private let store: MemoryStore

    init(client: OpenRouterClient, store: MemoryStore) {
        self.client = client
        self.store = store
    }

    func extractAndStore(userId: Int64, companionId: Int64, turnId: Int64, userText: String, assistantText: String, catalog: [CatalogEntry]) async throws {
        guard let extractModel = SelectionPolicy(role: .extract, catalog: catalog, pinnedModelId: nil).best() else { return }

        let systemPrompt = """
        Extract salient memories from this conversation turn. Return JSON array of objects with keys: "content" (string), "kind" (one of: fact, preference, event, emotion), "salience" (0.0-1.0). If nothing notable, return [].
        """
        let messages = [
            Message(role: "system", content: systemPrompt),
            Message(role: "user", content: userText),
            Message(role: "assistant", content: assistantText),
        ]

        let raw = try await client.completeChat(model: extractModel.id, messages: messages)
        let cleaned = Self.stripCodeFences(raw)
        guard let data = cleaned.data(using: .utf8),
              let extractions = try? JSONDecoder().decode([Extraction].self, from: data)
        else { return }

        for extraction in extractions {
            guard !extraction.content.isEmpty else { continue }
            let isDup = try await store.deduplicateMemory(content: extraction.content, companionId: companionId)
            guard !isDup else { continue }
            try await store.insertMemory(
                userId: userId,
                companionId: companionId,
                content: extraction.content,
                kind: extraction.kind,
                salience: extraction.salience,
                sourceTurnId: turnId
            )
        }
    }

    static func stripCodeFences(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {
            if let firstNewline = result.firstIndex(of: "\n") {
                result = String(result[result.index(after: firstNewline)...])
            }
        }
        if result.hasSuffix("```") {
            result = String(result.dropLast(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return result
    }
}

private struct Extraction: Codable {
    let content: String
    let kind: String
    let salience: Double
}
