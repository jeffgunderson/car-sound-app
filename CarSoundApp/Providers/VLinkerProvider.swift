import Foundation
import os

@MainActor
final class VLinkerProvider: VehicleDataProvider {
    private let logger = Logger(subsystem: "com.jeffgunderson.CarSoundApp", category: "VLinker")

    private(set) var connectionStatus: ConnectionStatus = .unavailable

    var stateStream: AsyncStream<VehicleState> {
        AsyncStream { _ in
            // Real BLE/OBD implementation will publish live VehicleState here.
        }
    }

    func start() async {
        logger.info("vLinker integration not implemented yet")
        connectionStatus = .unavailable
    }

    func stop() async {
        connectionStatus = .unavailable
    }
}

extension VLinkerProvider: @unchecked Sendable {}
