import Foundation

actor OpenRouterClient {
    private let baseURL = "https://openrouter.ai/api/v1"
    private let session: URLSession
    private let decoder: JSONDecoder

    private var apiKey: String = ""

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        config.httpMaximumConnectionsPerHost = 5
        config.httpShouldUsePipelining = true
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    func setKey(_ key: String) { apiKey = key }

    func prewarm() async {
        guard !apiKey.isEmpty else { return }
        let url = URL(string: "\(baseURL)/models")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 5
        guard let (_, response) = try? await session.data(for: req),
              let http = response as? HTTPURLResponse, http.statusCode == 200
        else { return }
    }

    func streamChat(model: String, messages: [Message], maxTokens: Int = 1024) -> AsyncThrowingStream<String, Error> {
        let key = apiKey
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    guard !key.isEmpty else { continuation.finish(throwing: ClientError.noKey); return }
                    let body = ChatRequest(model: model, messages: messages, stream: true, maxTokens: maxTokens)
                    var req = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
                    req.httpMethod = "POST"
                    req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.httpBody = try JSONEncoder().encode(body)

                    let (bytes, response) = try await session.bytes(for: req)
                    guard Task.isCancelled == false else { continuation.finish(throwing: CancellationError()); return }
                    guard let http = response as? HTTPURLResponse else {
                        continuation.finish(throwing: ClientError.invalidResponse)
                        return
                    }
                    guard http.statusCode == 200 else {
                        continuation.finish(throwing: ClientError.httpError(http.statusCode))
                        return
                    }

                    for try await line in bytes.lines {
                        try Task.checkCancellation()
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
                } catch is CancellationError {
                    continuation.finish(throwing: CancellationError())
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func completeChat(model: String, messages: [Message]) async throws -> String {
        let key = apiKey
        guard !key.isEmpty else { throw ClientError.noKey }
        let body = ChatRequest(model: model, messages: messages, stream: false, maxTokens: 1024)
        var req = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ClientError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try decoder.decode(ChatResponse.self, from: data)
        return decoded.choices?.first?.message.content ?? ""
    }

    func testConnection(model: String) async throws -> String {
        guard !apiKey.isEmpty else { throw ClientError.noKey }
        let messages = [Message(role: "user", content: "Respond with only the word: OK")]
        let resp = try await completeChat(model: model, messages: messages)
        return resp
    }

    func generateImage(model: String, prompt: String, inputReferenceDataURLs: [String] = []) async throws -> Data {
        let key = apiKey
        guard !key.isEmpty else { throw ClientError.noKey }
        let body = ImageRequestInputReferences(
            model: model,
            prompt: prompt,
            n: 1,
            size: "1024x1024",
            inputReferences: inputReferenceDataURLs.isEmpty ? nil : inputReferenceDataURLs.map { ["url": $0] }
        )
        var req = URLRequest(url: URL(string: "\(baseURL)/images")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ClientError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try decoder.decode(ImageResponse.self, from: data)

        if let b64 = decoded.data.first?.b64Json, let imageData = Data(base64Encoded: b64) {
            return imageData
        }
        if let urlStr = decoded.data.first?.url, let url = URL(string: urlStr) {
            let (imageData, _) = try await session.data(from: url)
            return imageData
        }
        throw ClientError.invalidResponse
    }
}

enum ClientError: Error {
    case noKey
    case invalidResponse
    case httpError(Int)
}

private struct ImageRequestInputReferences: Codable {
    let model: String
    let prompt: String
    let n: Int?
    let size: String?
    let inputReferences: [[String: String]]?

    enum CodingKeys: String, CodingKey {
        case model, prompt, n, size
        case inputReferences = "input_references"
    }
}
