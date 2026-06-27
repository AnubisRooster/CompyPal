import Foundation

actor FileCache {
    private let fileManager = FileManager.default
    private var cacheDir: URL {
        let dir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("com.ailtron.cache", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func write(data: Data, key: String) throws {
        let url = cacheDir.appendingPathComponent(key)
        try data.write(to: url, options: .atomic)
    }

    func read(key: String) -> Data? {
        let url = cacheDir.appendingPathComponent(key)
        return try? Data(contentsOf: url)
    }

    func exists(key: String) -> Bool {
        fileManager.fileExists(atPath: cacheDir.appendingPathComponent(key).path)
    }

    func url(for key: String) -> URL {
        cacheDir.appendingPathComponent(key)
    }
}
