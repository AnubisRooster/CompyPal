import Foundation
import AVFoundation
import GRDB
import OSLog

private let memoryLog = Logger(subsystem: "ai.companion", category: "memory")

final class MemoryStore: @unchecked Sendable {
    private let db: DatabaseManager

    init(db: DatabaseManager = .shared) {
        self.db = db
    }

    // MARK: - User

    func ensureUser(name: String = "User") async throws -> Int64 {
        let queue = try await db.open()
        return try await queue.write { db in
            if let row = try Row.fetchOne(db, sql: "SELECT id FROM \"user\" ORDER BY id LIMIT 1") {
                return row["id"]
            }
            try db.execute(sql: "INSERT INTO \"user\" (name) VALUES (?)", arguments: [name])
            return db.lastInsertedRowID
        }
    }

    // MARK: - Companion

    func ensureSeedCompanions(userId: Int64) async throws {
        let queue = try await db.open()
        try await queue.write { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM companion WHERE user_id = ?", arguments: [userId]) ?? 0
            guard count == 0 else { return }

            let now = Date()

            try db.execute(sql: "INSERT INTO companion (user_id, name, created_at) VALUES (?, ?, ?)", arguments: [userId, "Atlas", now])
            let atlasId = db.lastInsertedRowID
            for (traitName, intensity) in [("friendly", 0.85), ("thoughtful", 0.75), ("calm", 0.7), ("witty", 0.6)] {
                try db.execute(sql: "INSERT INTO personality_trait (companion_id, name, intensity) VALUES (?, ?, ?)", arguments: [atlasId, traitName, intensity])
            }
            for (key, value) in [("hair_color", "brown"), ("hair_length", "short"), ("hair_style", "straight"), ("eye_color", "blue"), ("skin_tone", "medium")] {
                try db.execute(sql: "INSERT INTO appearance_attribute (companion_id, key, value) VALUES (?, ?, ?)", arguments: [atlasId, key, value])
            }
            try db.execute(sql: "INSERT INTO voice (companion_id, system_voice_id) VALUES (?, ?)", arguments: [atlasId, VoicePicker.selectVoice(gender: .male)])

            try db.execute(sql: "INSERT INTO companion (user_id, name, glb_asset, created_at) VALUES (?, ?, ?, ?)", arguments: [userId, "Riven", "riven", now])
            let rivenId = db.lastInsertedRowID
            for (traitName, intensity) in [("curious", 0.9), ("playful", 0.8), ("energetic", 0.7), ("wise", 0.6)] {
                try db.execute(sql: "INSERT INTO personality_trait (companion_id, name, intensity) VALUES (?, ?, ?)", arguments: [rivenId, traitName, intensity])
            }
            for (key, value) in [("hair_color", "red"), ("hair_length", "long"), ("hair_style", "wavy"), ("eye_color", "green"), ("skin_tone", "light")] {
                try db.execute(sql: "INSERT INTO appearance_attribute (companion_id, key, value) VALUES (?, ?, ?)", arguments: [rivenId, key, value])
            }
            try db.execute(sql: "INSERT INTO voice (companion_id, system_voice_id) VALUES (?, ?)", arguments: [rivenId, VoicePicker.selectVoice(gender: .female)])
        }
        memoryLog.info("ensureSeedCompanions: seeded Atlas + Riven for userId=\(userId)")
    }

    func createCompanion(userId: Int64, name: String, traits: [(String, Double)], appearance: [(String, String)], glbAsset: String? = nil, voiceId: String? = nil) async throws -> Int64 {
        let queue = try await db.open()
        let resolvedVoice = voiceId ?? VoicePicker.selectVoice()
        return try await queue.write { db in
            try db.execute(sql: "INSERT INTO companion (user_id, name, glb_asset, created_at) VALUES (?, ?, ?, ?)", arguments: [userId, name, glbAsset, Date()])
            let companionId = db.lastInsertedRowID
            for (traitName, intensity) in traits {
                try db.execute(sql: "INSERT INTO personality_trait (companion_id, name, intensity) VALUES (?, ?, ?)", arguments: [companionId, traitName, intensity])
            }
            for (key, value) in appearance {
                try db.execute(sql: "INSERT INTO appearance_attribute (companion_id, key, value) VALUES (?, ?, ?)", arguments: [companionId, key, value])
            }
            try db.execute(sql: "INSERT INTO voice (companion_id, system_voice_id) VALUES (?, ?)", arguments: [companionId, resolvedVoice])
            return companionId
        }
    }

    func voiceId(companionId: Int64) async throws -> String? {
        let queue = try await db.open()
        return try await queue.read { db in
            try String.fetchOne(db, sql: "SELECT system_voice_id FROM voice WHERE companion_id = ?", arguments: [companionId])
        }
    }

    func companions(userId: Int64) async throws -> [CompanionInfo] {
        let queue = try await db.open()
        return try await queue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT c.id, c.name, c.relationship_stage, c.turn_count, c.created_at, c.glb_asset
                FROM companion c WHERE c.user_id = ?
                ORDER BY c.created_at DESC, c.id DESC
            """, arguments: [userId])
            return try rows.map { row in
                let id: Int64 = row["id"]
                let traits = try personalityTraits(companionId: id, db: db)
                let appearance = try appearanceAttributes(companionId: id, db: db)
                let voiceId = try String.fetchOne(db, sql: "SELECT system_voice_id FROM voice WHERE companion_id = ?", arguments: [id])
                return CompanionInfo(
                    id: id,
                    name: row["name"],
                    relationshipStage: row["relationship_stage"],
                    turnCount: row["turn_count"],
                    glbAsset: row["glb_asset"],
                    createdAt: row["created_at"],
                    traits: traits,
                    appearance: appearance,
                    voiceId: voiceId
                )
            }
        }
    }

    func companion(id: Int64) async throws -> CompanionInfo? {
        let queue = try await db.open()
        return try await queue.read { db in
            guard let row = try Row.fetchOne(db, sql: "SELECT * FROM companion WHERE id = ?", arguments: [id]) else { return nil }
            let traits = try personalityTraits(companionId: id, db: db)
            let appearance = try appearanceAttributes(companionId: id, db: db)
            let voiceId = try String.fetchOne(db, sql: "SELECT system_voice_id FROM voice WHERE companion_id = ?", arguments: [id])
            return CompanionInfo(
                id: row["id"],
                name: row["name"],
                relationshipStage: row["relationship_stage"],
                turnCount: row["turn_count"],
                glbAsset: row["glb_asset"],
                createdAt: row["created_at"],
                traits: traits,
                appearance: appearance,
                voiceId: voiceId
            )
        }
    }

    // MARK: - Conversation

    func insertTurn(companionId: Int64, role: String, text: String) async throws -> Int64 {
        let queue = try await db.open()
        return try await queue.write { db in
            try db.execute(sql: "INSERT INTO conversation_turn (companion_id, role, text, created_at) VALUES (?, ?, ?, ?)", arguments: [companionId, role, text, Date()])
            let turnId = db.lastInsertedRowID
            try db.execute(sql: "UPDATE companion SET turn_count = turn_count + 1 WHERE id = ?", arguments: [companionId])
            return turnId
        }
    }

    func recentTurns(companionId: Int64, limit: Int = 10) async throws -> [(role: String, text: String)] {
        let queue = try await db.open()
        return try await queue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT role, text FROM conversation_turn
                WHERE companion_id = ? ORDER BY id DESC LIMIT ?
            """, arguments: [companionId, limit])
            return rows.reversed().map { ($0["role"], $0["text"]) }
        }
    }

    // MARK: - Memory

    func insertMemory(userId: Int64, companionId: Int64?, content: String, kind: String, salience: Double, sourceTurnId: Int64?) async throws {
        let queue = try await db.open()
        try await queue.write { db in
            try db.execute(sql: """
                INSERT INTO memory (user_id, companion_id, content, kind, salience, source_turn_id, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, arguments: [userId, companionId, content, kind, salience, sourceTurnId, Date()])
        }
    }

    func salientMemories(userId: Int64, companionId: Int64, limit: Int = 5) async throws -> [MemoryInfo] {
        let queue = try await db.open()
        return try await queue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT content, kind, salience, created_at FROM memory
                WHERE user_id = ? AND (companion_id IS NULL OR companion_id = ?)
                ORDER BY salience DESC, created_at DESC LIMIT ?
            """, arguments: [userId, companionId, limit])
            return rows.map { row in
                MemoryInfo(content: row["content"], kind: row["kind"], salience: row["salience"], createdAt: row["created_at"])
            }
        }
    }

    func deduplicateMemory(content: String, companionId: Int64) async throws -> Bool {
        let queue = try await db.open()
        // SQL's TRIM only strips leading/trailing whitespace, so it can't reproduce
        // the internal-whitespace collapse below. Compare with identical normalization
        // applied in Swift to both the candidate and the stored rows.
        let normalized = Self.normalizeMemoryContent(content)
        return try await queue.read { db in
            let existing = try String.fetchAll(db, sql: "SELECT content FROM memory WHERE companion_id = ?", arguments: [companionId])
            return existing.contains { Self.normalizeMemoryContent($0) == normalized }
        }
    }

    static func normalizeMemoryContent(_ content: String) -> String {
        content
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    // MARK: - Appearance

    func updateAppearance(companionId: Int64, key: String, value: String) async throws {
        let queue = try await db.open()
        try await queue.write { db in
            let existing = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM appearance_attribute WHERE companion_id = ? AND key = ?", arguments: [companionId, key]) ?? 0
            if existing > 0 {
                try db.execute(sql: "UPDATE appearance_attribute SET value = ? WHERE companion_id = ? AND key = ?", arguments: [value, companionId, key])
            } else {
                try db.execute(sql: "INSERT INTO appearance_attribute (companion_id, key, value) VALUES (?, ?, ?)", arguments: [companionId, key, value])
            }
        }
    }

    // MARK: - Relationship

    func liveTurnCount(companionId: Int64) async throws -> Int {
        let queue = try await db.open()
        return try await queue.read { db in
            try Int.fetchOne(db, sql: "SELECT turn_count FROM companion WHERE id = ?", arguments: [companionId]) ?? 0
        }
    }

    func relationshipStage(companionId: Int64) async throws -> String {
        let queue = try await db.open()
        return try await queue.read { db in
            try String.fetchOne(db, sql: "SELECT relationship_stage FROM companion WHERE id = ?", arguments: [companionId]) ?? "acquaintance"
        }
    }

    func clearAll() async throws {
        let queue = try await db.open()
        try await queue.write { db in
            try db.execute(sql: "DELETE FROM memory")
            try db.execute(sql: "DELETE FROM conversation_turn")
            try db.execute(sql: "DELETE FROM personality_trait")
            try db.execute(sql: "DELETE FROM appearance_attribute")
            try db.execute(sql: "DELETE FROM voice")
            try db.execute(sql: "DELETE FROM companion")
            try db.execute(sql: "DELETE FROM \"user\"")
        }
    }

    func promoteStage(companionId: Int64) async throws {
        let queue = try await db.open()
        try await queue.write { db in
            let current = try String.fetchOne(db, sql: "SELECT relationship_stage FROM companion WHERE id = ?", arguments: [companionId]) ?? "acquaintance"
            let next: String
            switch current {
            case "acquaintance": next = "friend"
            case "friend": next = "confidant"
            default: return
            }
            try db.execute(sql: "UPDATE companion SET relationship_stage = ? WHERE id = ?", arguments: [next, companionId])
        }
    }

}

private func personalityTraits(companionId: Int64, db: GRDB.Database) throws -> [(String, Double)] {
    let rows = try Row.fetchAll(db, sql: "SELECT name, intensity FROM personality_trait WHERE companion_id = ?", arguments: [companionId])
    return rows.map { ($0["name"], $0["intensity"] as Double) }
}

private func appearanceAttributes(companionId: Int64, db: GRDB.Database) throws -> [(String, String)] {
    let rows = try Row.fetchAll(db, sql: "SELECT key, value FROM appearance_attribute WHERE companion_id = ?", arguments: [companionId])
    return rows.map { ($0["key"], $0["value"]) }
}

struct CompanionInfo: Identifiable, Hashable {
    let id: Int64
    let name: String
    let relationshipStage: String
    let turnCount: Int
    let glbAsset: String?
    let createdAt: Date
    let traits: [(String, Double)]
    let appearance: [(String, String)]
    let voiceId: String?

    var level: Int { min(turnCount / 5 + 1, 50) }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CompanionInfo, rhs: CompanionInfo) -> Bool {
        lhs.id == rhs.id
    }
}

struct MemoryInfo {
    let content: String
    let kind: String
    let salience: Double
    let createdAt: Date
}
