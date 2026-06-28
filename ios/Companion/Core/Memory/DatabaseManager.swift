import Foundation
import GRDB

actor DatabaseManager {
    static let shared = DatabaseManager()

    private var dbQueue: DatabaseQueue?

    func open() throws -> DatabaseQueue {
        if let queue = dbQueue { return queue }
        let dir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dbURL = dir.appendingPathComponent("companion.sqlite")
        let queue = try DatabaseQueue(path: dbURL.path)
        try runMigrations(queue)
        dbQueue = queue
        return queue
    }

    private func runMigrations(_ db: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1_initial") { db in
            try db.create(table: "user") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text)
            }
            try db.create(table: "companion") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("user_id", .integer).notNull().references("user", onDelete: .cascade)
                t.column("name", .text).notNull()
                t.column("relationship_stage", .text).notNull().defaults(to: "acquaintance")
                t.column("turn_count", .integer).notNull().defaults(to: 0)
                t.column("glb_asset", .text)
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }
            try db.create(table: "personality_trait") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("companion_id", .integer).notNull().references("companion", onDelete: .cascade)
                t.column("name", .text).notNull()
                t.column("intensity", .double).notNull().defaults(to: 1.0)
            }
            try db.create(table: "appearance_attribute") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("companion_id", .integer).notNull().references("companion", onDelete: .cascade)
                t.column("key", .text).notNull()
                t.column("value", .text).notNull()
            }
            try db.create(table: "voice") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("companion_id", .integer).notNull().references("companion", onDelete: .cascade).unique()
                t.column("system_voice_id", .text).notNull()
                t.column("pitch", .double).notNull().defaults(to: 1.0)
                t.column("rate", .double).notNull().defaults(to: 0.5)
            }
            try db.create(table: "memory") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("user_id", .integer).notNull().references("user", onDelete: .cascade)
                t.column("companion_id", .integer).references("companion", onDelete: .cascade)
                t.column("content", .text).notNull()
                t.column("kind", .text).notNull()
                t.column("salience", .double).notNull().defaults(to: 0.5)
                t.column("source_turn_id", .integer).references("conversation_turn", onDelete: .setNull)
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }
            try db.create(table: "conversation_turn") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("companion_id", .integer).notNull().references("companion", onDelete: .cascade)
                t.column("role", .text).notNull()
                t.column("text", .text).notNull()
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }
        }
        try migrator.migrate(db)
    }
}
