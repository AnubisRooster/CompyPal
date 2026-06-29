import Foundation

actor CatalogFetcher {
    private let session: URLSession
    private let baseURL: String
    private let decoder: JSONDecoder

    init(baseURL: String = "https://openrouter.ai/api/v1") {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    func fetch(apiKey: String) async throws -> [CatalogEntry] {
        // Fetch each endpoint independently so a failure of one (e.g. the optional
        // image-models endpoint) doesn't discard models successfully fetched from the other.
        async let chatModels = try? fetchModels(apiKey: apiKey, path: "\(baseURL)/models")
        async let imageModels = try? fetchModels(apiKey: apiKey, path: "\(baseURL)/images/models")
        let merged = (await chatModels ?? []) + (await imageModels ?? [])
        if merged.isEmpty { throw CatalogError.fetchFailed }
        return merged
    }

    private func fetchModels(apiKey: String, path: String) async throws -> [CatalogEntry] {
        var req = URLRequest(url: URL(string: path)!)
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            return []
        }
        let decoded = try decoder.decode(CatalogResponse.self, from: data)
        return decoded.data
    }
}

enum CatalogError: Error {
    case fetchFailed
}
