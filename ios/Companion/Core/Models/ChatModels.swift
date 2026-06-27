import Foundation

struct UserMessage: Codable {
    let type: String
    let companionId: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case type, text
        case companionId = "companion_id"
    }
}

struct ServerToken: Codable {
    let type: String
    let text: String
}

struct ServerEmotion: Codable {
    let type: String
    let state: String
}

struct ServerDone: Codable {
    let type: String
}

struct ServerError: Codable {
    let type: String
    let message: String
}
