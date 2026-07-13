import Foundation

enum ConnectionStatus: String, Sendable {
    case disconnected
    case connecting
    case connected
    case unavailable

    var displayName: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .unavailable:
            return "Unavailable"
        }
    }
}

enum DataSource: String, CaseIterable, Identifiable, Codable, Sendable {
    case simulator
    case vLinker

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .simulator:
            return "Simulator"
        case .vLinker:
            return "vLinker"
        }
    }
}
