import Foundation

enum SimulatorScenario: String, CaseIterable, Identifiable, Sendable {
    case idle
    case acceleration
    case cruise
    case revLimiter
    case stoplight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .idle:
            return "Idle"
        case .acceleration:
            return "Acceleration"
        case .cruise:
            return "Cruise"
        case .revLimiter:
            return "Rev Limiter"
        case .stoplight:
            return "Stoplight Cycle"
        }
    }
}

@MainActor
final class SimulatorVehicleProvider: VehicleDataProvider {
    private(set) var connectionStatus: ConnectionStatus = .disconnected

    let stateStream: AsyncStream<VehicleState>
    private var continuation: AsyncStream<VehicleState>.Continuation?

    private var publishTask: Task<Void, Never>?
    private var scenarioTask: Task<Void, Never>?

    private var currentState = VehicleState.idle
    private var manualControlEnabled = true

    init() {
        var capturedContinuation: AsyncStream<VehicleState>.Continuation?
        stateStream = AsyncStream { continuation in
            capturedContinuation = continuation
        }
        continuation = capturedContinuation
    }

    func start() async {
        guard publishTask == nil else { return }
        connectionStatus = .connected
        publishCurrentState()
        publishTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
                await self?.publishCurrentState()
            }
        }
    }

    func stop() async {
        scenarioTask?.cancel()
        scenarioTask = nil
        publishTask?.cancel()
        publishTask = nil
        connectionStatus = .disconnected
    }

    func setManualControlEnabled(_ enabled: Bool) {
        manualControlEnabled = enabled
        if enabled {
            scenarioTask?.cancel()
            scenarioTask = nil
        }
    }

    func setRPM(_ rpm: Double) {
        guard manualControlEnabled else { return }
        currentState.rpm = min(max(rpm, 500), 7000)
        publishCurrentState()
    }

    func setThrottle(_ throttle: Double) {
        guard manualControlEnabled else { return }
        currentState.throttle = min(max(throttle, 0), 100)
        publishCurrentState()
    }

    func setManualState(rpm: Double, throttle: Double) {
        guard manualControlEnabled else { return }
        currentState = VehicleState(
            rpm: min(max(rpm, 500), 7000),
            throttle: min(max(throttle, 0), 100)
        )
        publishCurrentState()
    }

    func snapshotState() -> VehicleState {
        currentState
    }

    func applyScenario(_ scenario: SimulatorScenario) {
        scenarioTask?.cancel()
        manualControlEnabled = false

        scenarioTask = Task { [weak self] in
            guard let self else { return }

            switch scenario {
            case .idle:
                await self.runIdle()
            case .acceleration:
                await self.runAcceleration()
            case .cruise:
                await self.runCruise()
            case .revLimiter:
                await self.runRevLimiter()
            case .stoplight:
                await self.runStoplightCycle()
            }

            await MainActor.run {
                self.manualControlEnabled = true
            }
        }
    }

    private func publishCurrentState() {
        continuation?.yield(currentState)
    }

    private func updateState(rpm: Double, throttle: Double) async {
        currentState = VehicleState(rpm: rpm, throttle: throttle)
        publishCurrentState()
    }

    private func animate(
        from start: VehicleState,
        to end: VehicleState,
        duration: TimeInterval,
        steps: Int
    ) async {
        guard steps > 0 else { return }
        let stepDuration = duration / Double(steps)

        for step in 0...steps {
            if Task.isCancelled { return }
            let progress = Double(step) / Double(steps)
            let rpm = start.rpm + (end.rpm - start.rpm) * progress
            let throttle = start.throttle + (end.throttle - start.throttle) * progress
            await updateState(rpm: rpm, throttle: throttle)
            try? await Task.sleep(for: .seconds(stepDuration))
        }
    }

    private func runIdle() async {
        await updateState(rpm: 750, throttle: 0)
    }

    private func runAcceleration() async {
        await animate(
            from: VehicleState(rpm: 750, throttle: 0),
            to: VehicleState(rpm: 5500, throttle: 85),
            duration: 3.0,
            steps: 60
        )
    }

    private func runCruise() async {
        await updateState(rpm: 2200, throttle: 25)
    }

    private func runRevLimiter() async {
        for _ in 0..<8 {
            if Task.isCancelled { return }
            await animate(
                from: VehicleState(rpm: 5800, throttle: 100),
                to: VehicleState(rpm: 6200, throttle: 100),
                duration: 0.12,
                steps: 4
            )
            await animate(
                from: VehicleState(rpm: 6200, throttle: 100),
                to: VehicleState(rpm: 5800, throttle: 90),
                duration: 0.12,
                steps: 4
            )
        }
    }

    private func runStoplightCycle() async {
        await runIdle()
        try? await Task.sleep(for: .seconds(2))
        await runAcceleration()
        try? await Task.sleep(for: .seconds(1))
        await runCruise()
        try? await Task.sleep(for: .seconds(2))
        await animate(
            from: VehicleState(rpm: 2200, throttle: 25),
            to: VehicleState(rpm: 900, throttle: 0),
            duration: 2.0,
            steps: 40
        )
        await runIdle()
        await MainActor.run {
            manualControlEnabled = true
        }
    }
}

extension SimulatorVehicleProvider: @unchecked Sendable {}
