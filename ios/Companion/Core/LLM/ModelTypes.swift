import Foundation

enum ModelRole: String, Codable, CaseIterable {
    case chat, extract, image
}

struct CatalogEntry: Codable, Hashable, Sendable {
    let id: String
    let name: String?
    let pricing: Pricing
    let contextLength: Int?
    let modalities: Modalities?
    let supportedParameters: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name, pricing
        case contextLength = "context_length"
        case modalities = "modalities"
        case supportedParameters = "supported_parameters"
    }
}

struct Pricing: Codable, Hashable, Sendable {
    let prompt: Double
    let completion: Double
    let image: Double?
    let perRequest: Double?

    enum CodingKeys: String, CodingKey {
        case prompt, completion, image
        case perRequest = "per_request"
    }

    static let zero = Pricing(prompt: 0, completion: 0, image: nil, perRequest: nil)
}

struct Modalities: Codable, Hashable, Sendable {
    let input: [String]?
    let output: [String]?
}

struct CatalogResponse: Codable {
    let data: [CatalogEntry]
}

struct CatalogCacheData: Codable {
    let entries: [CatalogEntry]
    let lastRefreshed: Date

    enum CodingKeys: String, CodingKey {
        case entries
        case lastRefreshed = "last_refreshed"
    }
}

struct ChatRequest: Codable {
    let model: String
    let messages: [Message]
    let stream: Bool
    let maxTokens: Int?

    enum CodingKeys: String, CodingKey {
        case model, messages, stream
        case maxTokens = "max_tokens"
    }
}

struct Message: Codable, Hashable, Sendable {
    let role: String
    let content: String
}

struct ChatChunk: Codable {
    let choices: [ChunkChoice]?
}

struct ChunkChoice: Codable {
    let delta: Delta
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case delta
        case finishReason = "finish_reason"
    }
}

struct Delta: Codable {
    let content: String?
}

struct ImageRequest: Codable {
    let model: String
    let prompt: String
    let n: Int?
    let size: String?

    enum CodingKeys: String, CodingKey {
        case model, prompt, n, size
    }
}

struct ImageResponse: Codable {
    let data: [ImageData]
}

struct ImageData: Codable {
    let url: String?
    let b64Json: String?

    enum CodingKeys: String, CodingKey {
        case url
        case b64Json = "b64_json"
    }
}
