import Foundation
import Network

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected = true
    @Published private(set) var connectionDescription = ""

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "network.monitor")

    private init() {
        monitor.start(queue: queue)
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionDescription = path.status == .satisfied ? "Connected" : "Offline"
            }
        }
    }
}
