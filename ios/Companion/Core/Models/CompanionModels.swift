import Foundation

struct Trait: Codable {
    let name: String
    let intensity: Double
}

struct CreateCompanionRequest: Codable {
    let name: String
    let traits: [Trait]
    let appearance: [String: String]
    let voiceId: String?

    enum CodingKeys: String, CodingKey {
        case name, traits, appearance
        case voiceId = "voice_id"
    }
}

struct CreateCompanionResponse: Codable {
    let companionId: String

    enum CodingKeys: String, CodingKey {
        case companionId = "companion_id"
    }
}

struct CompanionState: Codable {
    let companionId: String
    let name: String
    let traits: [Trait]
    let appearance: [String: String]
    let voiceId: String?
    let relationshipStage: String
    let turnCount: Int

    enum CodingKeys: String, CodingKey {
        case companionId = "companion_id"
        case name, traits, appearance
        case voiceId = "voice_id"
        case relationshipStage = "relationship_stage"
        case turnCount = "turn_count"
    }
}
