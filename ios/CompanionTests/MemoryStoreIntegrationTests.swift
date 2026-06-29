import Foundation
import Testing
import GRDB
@testable import Companion

@Test func migrationCreatesTables() throws {
    let dbURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("test_\(UUID().uuidString).sqlite")
    let queue = try DatabaseQueue(path: dbURL.path)
    try DatabaseManager.runMigrations(queue)

    let tables: [String] = try queue.read { db in
        try Row.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
            .map { $0["name"] as String }
    }
    #expect(tables.contains("user"))
    #expect(tables.contains("companion"))
    #expect(tables.contains("conversation_turn"))
    #expect(tables.contains("memory"))
    #expect(tables.contains("personality_trait"))
    #expect(tables.contains("appearance_attribute"))
    #expect(tables.contains("voice"))
}

@Test func storeReadWriteRoundtrip() async throws {
    let dbURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("test_\(UUID().uuidString).sqlite")
    let queue = try DatabaseQueue(path: dbURL.path)
    try DatabaseManager.runMigrations(queue)
    let dbManager = DatabaseManager(override: queue)
    let store = MemoryStore(db: dbManager)

    let userId = try await store.ensureUser(name: "Test")
    let cid = try await store.createCompanion(userId: userId, name: "Bot", traits: [("friendly", 0.8)], appearance: [("hair_color", "brown")])
    let info = try #require(try await store.companion(id: cid))
    #expect(info.name == "Bot")
    #expect(info.turnCount == 0)
}
