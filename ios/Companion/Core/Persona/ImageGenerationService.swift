import Foundation
import UIKit

actor ImageGenerationService {
    private let client: OpenRouterClient
    private let cache = FileCache()

    init(client: OpenRouterClient) {
        self.client = client
    }

    func generateForCompanion(companionId: Int64, prompt: String, catalog: [CatalogEntry], referenceURL: URL? = nil) async throws -> URL? {
        guard let model = SelectionPolicy(role: .image, catalog: catalog, pinnedModelId: nil).best() else { return nil }
        var references: [URL] = []
        if let refURL = referenceURL {
            references = [refURL]
        }
        let imageData = try await client.generateImage(model: model.id, prompt: prompt, inputReferences: references)

        let key = "companion_\(companionId)_reference"
        try await cache.write(data: imageData, key: key)

        let url = await cache.url(for: key)
        return url
    }

    func cachedImageURL(companionId: Int64) async -> URL? {
        let key = "companion_\(companionId)_reference"
        guard await cache.exists(key: key) else { return nil }
        return await cache.url(for: key)
    }

    func cachedImageData(companionId: Int64) async -> Data? {
        let key = "companion_\(companionId)_reference"
        return await cache.read(key: key)
    }
}
