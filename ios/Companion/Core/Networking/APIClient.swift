import Foundation

actor APIClient {
    enum ConnectionState {
        case disconnected, connecting, connected, reconnecting
    }

    private let baseURL: String
    private let session: URLSession
    private var webSocket: URLSessionWebSocketTask?
    private(set) var connectionState: ConnectionState = .disconnected
    private var reconnectAttempt = 0
    private let maxReconnectDelay: UInt64 = 16_000_000_000
    private var messageQueue: [String] = []
    private var reconnectTask: Task<Void, Never>?
    private var companionId: String?
    private var userId: String?

    private var onToken: ((String) -> Void)?
    private var onAudioChunk: ((Int, String) -> Void)?
    private var onEmotion: ((String) -> Void)?
    private var onAppearanceUpdate: ((String, [String: String]) -> Void)?
    private var onDone: (() -> Void)?
    private var onConnectionChange: ((ConnectionState) -> Void)?

    init(baseURL: String = "http://localhost:8000") {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
    }

    func setConnectionHandler(_ handler: @escaping (ConnectionState) -> Void) {
        onConnectionChange = handler
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
        self.companionId = companionId
        self.userId = userId
        self.onToken = onToken
        self.onAudioChunk = onAudioChunk
        self.onEmotion = onEmotion
        self.onAppearanceUpdate = onAppearanceUpdate
        self.onDone = onDone
        reconnectAttempt = 0
        messageQueue = []
        startConnection()
    }

    private func startConnection() {
        guard let cid = companionId, let uid = userId else { return }
        let wsBase = baseURL
            .replacingOccurrences(of: "http://", with: "ws://")
            .replacingOccurrences(of: "https://", with: "wss://")
        guard let url = URL(string: "\(wsBase)/ws/\(cid)?user_id=\(uid)") else { return }

        connectionState = reconnectAttempt > 0 ? .reconnecting : .connecting
        onConnectionChange?(connectionState)

        let wsSession = URLSession(configuration: .default)
        webSocket = wsSession.webSocketTask(with: url)
        webSocket?.resume()

        listen()

        for msg in messageQueue {
            sendMessage(msg)
        }
        messageQueue.removeAll()
    }

    func sendMessage(_ text: String) {
        guard let sock = webSocket, connectionState == .connected || connectionState == .connecting else {
            messageQueue.append(text)
            return
        }
        let msg = ["type": "user_message", "text": text]
        if let data = try? JSONSerialization.data(withJSONObject: msg) {
            sock.send(.data(data)) { _ in }
        }
    }

    func sendAudioTranscript(_ text: String) {
        guard let sock = webSocket else {
            messageQueue.append(text)
            return
        }
        let msg = ["type": "audio_transcript", "text": text]
        if let data = try? JSONSerialization.data(withJSONObject: msg) {
            sock.send(.data(data)) { _ in }
        }
    }

    func disconnectChat() {
        reconnectTask?.cancel()
        reconnectTask = nil
        messageQueue.removeAll()
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        connectionState = .disconnected
        onConnectionChange?(.disconnected)
    }

    private func listen() {
        webSocket?.receive { [weak self] result in
            Task { [weak self] in
                guard let self else { return }
                switch result {
                case .success(let message):
                    await self.handleReceive(message)
                    self.listen()
                case .failure:
                    await self.handleReconnect()
                }
            }
        }
    }

    private func handleReceive(_ message: URLSessionWebSocketTask.Message) {
        connectionState = .connected
        reconnectAttempt = 0
        switch message {
        case .string(let text):
            handleMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                handleMessage(text)
            }
        @unknown default:
            break
        }
    }

    private func handleReconnect() {
        let delay = min(UInt64(pow(2.0, Double(reconnectAttempt))) * 1_000_000_000, maxReconnectDelay)
        reconnectAttempt += 1
        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            await self?.startConnection()
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "token":
            if let t = json["text"] as? String { onToken?(t) }
        case "audio_chunk":
            if let seq = json["seq"] as? Int, let d = json["data"] as? String {
                onAudioChunk?(seq, d)
            }
        case "emotion":
            if let state = json["state"] as? String { onEmotion?(state) }
        case "appearance_update":
            if let url = json["asset_url"] as? String,
               let attrs = json["attributes"] as? [String: String] {
                onAppearanceUpdate?(url, attrs)
            }
        case "done":
            onDone?()
        case "error":
            if let msg = json["message"] as? String {
                onToken?("[Error: \(msg)]")
            }
        default:
            break
        }
    }
}
