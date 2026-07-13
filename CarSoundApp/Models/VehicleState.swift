import Foundation

struct VehicleState: Equatable, Sendable {
    var rpm: Double
    var throttle: Double

    static let idle = VehicleState(rpm: 750, throttle: 0)
}
