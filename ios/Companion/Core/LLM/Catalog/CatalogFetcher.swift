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
        var req = URLRequest(url: URL(string: "\(baseURL)/models")!)
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw CatalogError.fetchFailed
        }
        let decoded = try decoder.decode(CatalogResponse.self, from: data)
        return decoded.data
    }
}

enum CatalogError: Error {
    case fetchFailed
}
