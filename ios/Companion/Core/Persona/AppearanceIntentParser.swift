import Foundation

actor AppearanceIntentParser {
    private let client: OpenRouterClient

    init(client: OpenRouterClient) {
        self.client = client
    }

    func parse(userText: String, currentAppearance: [(String, String)], catalog: [CatalogEntry]) async throws -> AppearanceDelta? {
        guard let model = SelectionPolicy(role: .extract, catalog: catalog, pinnedModelId: nil).best() else { return nil }

        let current = currentAppearance.map { "\($0.0): \($0.1)" }.joined(separator: ", ")
        let knownAttrs = ParametricSchema.shared.allKeys().joined(separator: ", ")

        let systemPrompt = """
        You detect appearance-change intent. Given the user's message and current appearance, return a JSON object with keys: "attribute" (one of: \(knownAttrs)), "value" (the new value). Use exact terms from the schema. If the user is NOT requesting an appearance change, return empty JSON object {}.
        """

        let messages = [
            Message(role: "system", content: systemPrompt),
            Message(role: "user", content: "Current: \(current)"),
            Message(role: "user", content: userText),
        ]

        let raw = try await client.completeChat(model: model.id, messages: messages)
        let cleaned = Self.stripCodeFences(raw)
        guard let data = cleaned.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(ParsedIntent.self, from: data),
              !parsed.attribute.isEmpty
        else { return nil }

        return AppearanceDelta(attribute: parsed.attribute, value: parsed.value, declined: nil, suggestion: nil)
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

private struct ParsedIntent: Codable {
    let attribute: String
    let value: String
}
