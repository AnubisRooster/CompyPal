import Foundation
import GRDB

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

    func createCompanion(userId: Int64, name: String, traits: [(String, Double)], appearance: [(String, String)]) async throws -> Int64 {
        let queue = try await db.open()
        return try await queue.write { db in
            try db.execute(sql: "INSERT INTO companion (user_id, name) VALUES (?, ?)", arguments: [userId, name])
            let companionId = db.lastInsertedRowID
            for (traitName, intensity) in traits {
                try db.execute(sql: "INSERT INTO personality_trait (companion_id, name, intensity) VALUES (?, ?, ?)", arguments: [companionId, traitName, intensity])
            }
            for (key, value) in appearance {
                try db.execute(sql: "INSERT INTO appearance_attribute (companion_id, key, value) VALUES (?, ?, ?)", arguments: [companionId, key, value])
            }
            try db.execute(sql: "INSERT INTO voice (companion_id, system_voice_id) VALUES (?, ?)", arguments: [companionId, "com.apple.voice.compact.en-US.Samantha"])
            return companionId
        }
    }

    func companions(userId: Int64) async throws -> [CompanionInfo] {
        let queue = try await db.open()
        return try await queue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT c.id, c.name, c.relationship_stage, c.turn_count, c.created_at
                FROM companion c WHERE c.user_id = ?
                ORDER BY c.created_at DESC
            """, arguments: [userId])
            return try rows.map { row in
                let id: Int64 = row["id"]
                let traits = try personalityTraits(companionId: id, db: db)
                let appearance = try appearanceAttributes(companionId: id, db: db)
                return CompanionInfo(
                    id: id,
                    name: row["name"],
                    relationshipStage: row["relationship_stage"],
                    turnCount: row["turn_count"],
                    createdAt: row["created_at"],
                    traits: traits,
                    appearance: appearance
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
            return CompanionInfo(
                id: row["id"],
                name: row["name"],
                relationshipStage: row["relationship_stage"],
                turnCount: row["turn_count"],
                createdAt: row["created_at"],
                traits: traits,
                appearance: appearance
            )
        }
    }

    // MARK: - Conversation

    func insertTurn(companionId: Int64, role: String, text: String) async throws -> Int64 {
        let queue = try await db.open()
        return try await queue.write { db in
            try db.execute(sql: "INSERT INTO conversation_turn (companion_id, role, text) VALUES (?, ?, ?)", arguments: [companionId, role, text])
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
                INSERT INTO memory (user_id, companion_id, content, kind, salience, source_turn_id)
                VALUES (?, ?, ?, ?, ?, ?)
            """, arguments: [userId, companionId, content, kind, salience, sourceTurnId])
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

    func deduplicateMemory(content: String) async throws -> Bool {
        let queue = try await db.open()
        return try await queue.read { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM memory WHERE content = ?", arguments: [content]) ?? 0
            return count > 0
        }
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

    func relationshipStage(companionId: Int64) async throws -> String {
        let queue = try await db.open()
        return try await queue.read { db in
            try String.fetchOne(db, sql: "SELECT relationship_stage FROM companion WHERE id = ?", arguments: [companionId]) ?? "acquaintance"
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

struct CompanionInfo {
    let id: Int64
    let name: String
    let relationshipStage: String
    let turnCount: Int
    let createdAt: Date
    let traits: [(String, Double)]
    let appearance: [(String, String)]
}

struct MemoryInfo {
    let content: String
    let kind: String
    let salience: Double
    let createdAt: Date
}
