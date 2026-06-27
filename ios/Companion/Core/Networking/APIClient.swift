import Foundation

actor APIClient {
    private let baseURL: String
    private let session: URLSession
    private var webSocket: URLSessionWebSocketTask?

    init(baseURL: String = "http://localhost:8000") {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
    }

    func healthCheck() async throws -> Bool {
        var request = URLRequest(url: URL(string: "\(baseURL)/health")!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return false
        }

        let decoded = try JSONDecoder().decode(HealthResponse.self, from: data)
        return decoded.status == "ok"
    }

    func createCompanion(name: String, traits: [Trait], appearance: [String: String],
                         userId: String) async throws -> CreateCompanionResponse {
        let body = CreateCompanionRequest(name: name, traits: traits,
                                          appearance: appearance, voiceId: nil)
        var request = URLRequest(url: URL(string: "\(baseURL)/companions")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(CreateCompanionResponse.self, from: data)
    }

    func connectChat(companionId: String, userId: String,
                     onToken: @escaping (String) -> Void,
                     onAudioChunk: @escaping (Int, String) -> Void,
                     onEmotion: @escaping (String) -> Void,
                     onAppearanceUpdate: @escaping (String, [String: String]) -> Void,
                     onDone: @escaping () -> Void,
                     onError: @escaping (String) -> Void) {
        let wsBase = baseURL
            .replacingOccurrences(of: "http://", with: "ws://")
            .replacingOccurrences(of: "https://", with: "wss://")
        guard let url = URL(string: "\(wsBase)/ws/\(companionId)?user_id=\(userId)") else { return }

        let wsSession = URLSession(configuration: .default)
        webSocket = wsSession.webSocketTask(with: url)
        webSocket?.resume()

        listen(onToken: onToken, onAudioChunk: onAudioChunk,
               onEmotion: onEmotion, onAppearanceUpdate: onAppearanceUpdate,
               onDone: onDone, onError: onError)
    }

    func sendMessage(_ text: String) {
        let msg = ["type": "user_message", "text": text]
        if let data = try? JSONSerialization.data(withJSONObject: msg) {
            webSocket?.send(.data(data)) { _ in }
        }
    }

    func sendAudioTranscript(_ text: String) {
        let msg = ["type": "audio_transcript", "text": text]
        if let data = try? JSONSerialization.data(withJSONObject: msg) {
            webSocket?.send(.data(data)) { _ in }
        }
    }

    func disconnectChat() {
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
    }

    private func listen(onToken: @escaping (String) -> Void,
                        onAudioChunk: @escaping (Int, String) -> Void,
                        onEmotion: @escaping (String) -> Void,
                        onAppearanceUpdate: @escaping (String, [String: String]) -> Void,
                        onDone: @escaping () -> Void,
                        onError: @escaping (String) -> Void) {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text, onToken: onToken, onAudioChunk: onAudioChunk,
                                       onEmotion: onEmotion, onAppearanceUpdate: onAppearanceUpdate,
                                       onDone: onDone, onError: onError)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text, onToken: onToken, onAudioChunk: onAudioChunk,
                                           onEmotion: onEmotion, onAppearanceUpdate: onAppearanceUpdate,
                                           onDone: onDone, onError: onError)
                    }
                @unknown default:
                    break
                }
                self.listen(onToken: onToken, onAudioChunk: onAudioChunk,
                           onEmotion: onEmotion, onAppearanceUpdate: onAppearanceUpdate,
                           onDone: onDone, onError: onError)
            case .failure:
                onError("WebSocket disconnected")
            }
        }
    }

    private func handleMessage(_ text: String,
                                onToken: (String) -> Void,
                                onAudioChunk: (Int, String) -> Void,
                                onEmotion: (String) -> Void,
                                onAppearanceUpdate: (String, [String: String]) -> Void,
                                onDone: () -> Void,
                                onError: (String) -> Void) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "token":
            if let t = json["text"] as? String { onToken(t) }
        case "audio_chunk":
            if let seq = json["seq"] as? Int, let d = json["data"] as? String {
                onAudioChunk(seq, d)
            }
        case "emotion":
            if let state = json["state"] as? String { onEmotion(state) }
        case "appearance_update":
            if let url = json["asset_url"] as? String,
               let attrs = json["attributes"] as? [String: String] {
                onAppearanceUpdate(url, attrs)
            }
        case "done":
            onDone()
        case "error":
            if let msg = json["message"] as? String { onError(msg) }
        default:
            break
        }
    }
}
