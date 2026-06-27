import Foundation

actor OpenRouterClient {
    private let baseURL = "https://openrouter.ai/api/v1"
    private let session: URLSession
    private let decoder: JSONDecoder

    private var apiKey: String = ""

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    func setKey(_ key: String) { apiKey = key }

    func streamChat(model: String, messages: [Message], maxTokens: Int = 1024) -> AsyncThrowingStream<String, Error> {
        let key = apiKey
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let body = ChatRequest(model: model, messages: messages, stream: true, maxTokens: maxTokens)
                    var req = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
                    req.httpMethod = "POST"
                    req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.httpBody = try JSONEncoder().encode(body)

                    let (bytes, response) = try await session.bytes(for: req)
                    guard let http = response as? HTTPURLResponse else {
                        continuation.finish(throwing: ClientError.invalidResponse)
                        return
                    }
                    guard http.statusCode == 200 else {
                        continuation.finish(throwing: ClientError.httpError(http.statusCode))
                        return
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let json = String(line.dropFirst(6))
                        if json == "[DONE]" { break }
                        guard let data = json.data(using: .utf8),
                              let chunk = try? decoder.decode(ChatChunk.self, from: data),
                              let delta = chunk.choices?.first?.delta.content
                        else { continue }
                        continuation.yield(delta)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func completeChat(model: String, messages: [Message]) async throws -> String {
        let key = apiKey
        var body = ChatRequest(model: model, messages: messages, stream: false, maxTokens: 1024)
        var req = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ClientError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try decoder.decode(ChatChunk.self, from: data)
        return decoded.choices?.first?.delta.content ?? ""
    }

    func testConnection(model: String = "openai/gpt-4o-mini") async throws -> String {
        guard !apiKey.isEmpty else { throw ClientError.noKey }
        let messages = [Message(role: "user", content: "Respond with only the word: OK")]
        let resp = try await completeChat(model: model, messages: messages)
        return resp
    }
}

enum ClientError: Error {
    case noKey
    case invalidResponse
    case httpError(Int)
}
