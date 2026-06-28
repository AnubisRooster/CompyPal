import Foundation

enum ModelRole: String, Codable, CaseIterable {
    case chat, extract, image
}

struct CatalogEntry: Codable, Hashable, Sendable {
    let id: String
    let name: String?
    let pricing: Pricing
    let contextLength: Int?
    let architecture: Architecture?
    let supportedParameters: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name, pricing
        case contextLength = "context_length"
        case architecture
        case supportedParameters = "supported_parameters"
    }
}

struct Architecture: Codable, Hashable, Sendable {
    let inputModalities: [String]?
    let outputModalities: [String]?

    enum CodingKeys: String, CodingKey {
        case inputModalities = "input_modalities"
        case outputModalities = "output_modalities"
    }
}

struct Pricing: Codable, Hashable, Sendable {
    let prompt: Double
    let completion: Double
    let image: Double?
    let perRequest: Double?

    init(prompt: Double, completion: Double, image: Double? = nil, perRequest: Double? = nil) {
        self.prompt = prompt
        self.completion = completion
        self.image = image
        self.perRequest = perRequest
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        prompt = try Self.decodePrice(container, for: .prompt)
        completion = try Self.decodePrice(container, for: .completion)
        image = try container.decodeIfPresent(String.self, forKey: .image).flatMap { Double($0) }
        perRequest = try container.decodeIfPresent(String.self, forKey: .perRequest).flatMap { Double($0) }
    }

    private static func decodePrice(_ container: KeyedDecodingContainer<CodingKeys>, for key: CodingKeys) throws -> Double {
        if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: key) {
            return doubleVal
        }
        if let stringVal = try container.decodeIfPresent(String.self, forKey: key), let val = Double(stringVal) {
            return val
        }
        return 0
    }

    enum CodingKeys: String, CodingKey {
        case prompt, completion, image
        case perRequest = "per_request"
    }

    static let zero = Pricing(prompt: 0, completion: 0, image: nil, perRequest: nil)
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

// Non-streaming response
struct ChatResponse: Codable {
    let choices: [ResponseChoice]?
}

struct ResponseChoice: Codable {
    let message: ResponseMessage
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct ResponseMessage: Codable {
    let content: String?
}

// Streaming chunk (delta-based)
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
