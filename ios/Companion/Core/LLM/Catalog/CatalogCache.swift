import Foundation

actor CatalogCache {
    private let fileCache: FileCache
    private let ttl: TimeInterval
    private let cacheKey = "openrouter_catalog"

    private var cachedData: CatalogCacheData?

    init(ttl: TimeInterval = 43200) {
        self.fileCache = FileCache()
        self.ttl = ttl
    }

    func load() async -> CatalogCacheData? {
        if let data = cachedData { return data }
        guard let raw = await fileCache.read(key: cacheKey),
              let decoded = try? JSONDecoder().decode(CatalogCacheData.self, from: raw)
        else { return nil }
        cachedData = decoded
        return decoded
    }

    func save(entries: [CatalogEntry]) async throws {
        let data = CatalogCacheData(entries: entries, lastRefreshed: Date())
        let raw = try JSONEncoder().encode(data)
        try await fileCache.write(data: raw, key: cacheKey)
        cachedData = data
    }

    func needsRefresh() -> Bool {
        guard let cached = cachedData else { return true }
        return Date().timeIntervalSince(cached.lastRefreshed) > ttl
    }

    func isStale() -> Bool {
        cachedData == nil || needsRefresh()
    }

    func clear() {
        cachedData = nil
    }
}
