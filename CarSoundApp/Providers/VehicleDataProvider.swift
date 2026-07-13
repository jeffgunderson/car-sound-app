import Foundation

protocol VehicleDataProvider: AnyObject, Sendable {
    var connectionStatus: ConnectionStatus { get }
    var stateStream: AsyncStream<VehicleState> { get }

    func start() async
    func stop() async
}
