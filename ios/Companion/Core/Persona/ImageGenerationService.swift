import Foundation
import UIKit

actor ImageGenerationService {
    private let client: OpenRouterClient
    private let cache = FileCache()

    init(client: OpenRouterClient) {
        self.client = client
    }

    func generateForCompanion(companionId: Int64, prompt: String, catalog: [CatalogEntry], referenceData: Data? = nil) async throws -> URL? {
        guard let model = SelectionPolicy(role: .image, catalog: catalog, pinnedModelId: nil).best() else { return nil }
        var referenceDataURLs: [String] = []
        if let data = referenceData {
            referenceDataURLs = [Self.base64DataURL(data, mimeType: "image/png")]
        }
        let imageData = try await client.generateImage(model: model.id, prompt: prompt, inputReferenceDataURLs: referenceDataURLs)

        let key = "companion_\(companionId)_reference"
        try await cache.write(data: imageData, key: key)

        let url = await cache.url(for: key)
        return url
    }

    func cachedImageData(companionId: Int64) async -> Data? {
        let key = "companion_\(companionId)_reference"
        return await cache.read(key: key)
    }

    func hasCachedImage(companionId: Int64) async -> Bool {
        let key = "companion_\(companionId)_reference"
        return await cache.exists(key: key)
    }

    static func base64DataURL(_ data: Data, mimeType: String) -> String {
        "data:\(mimeType);base64,\(data.base64EncodedString())"
    }
}
