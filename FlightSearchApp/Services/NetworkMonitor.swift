import Foundation
import Network
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = true
    private var hasReceivedFirstUpdate = false

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "network.monitor")

    private init() {
        self.startMonitoring()
    }

    private func startMonitoring() {
            monitor.pathUpdateHandler = { [weak self] path in
                DispatchQueue.main.async {
                    if !(self?.hasReceivedFirstUpdate ?? false) {
                        self?.hasReceivedFirstUpdate = true
                        self?.isConnected = (path.status == .satisfied)
                    } else {
                        self?.isConnected = (path.status != .satisfied)
                    }
                }
            }
            monitor.start(queue: monitorQueue)
        }

    deinit {
        monitor.cancel()
    }
}
