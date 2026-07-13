import Foundation

enum EngineLoopTier: String, CaseIterable, Sendable {
    case idle
    case cruise
    case high

    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .cruise: return "Cruise"
        case .high: return "High"
        }
    }
}

enum SoundPlaybackKind: Equatable, Sendable {
    case sampleLoops
    case synthesized(cylinders: Int)
}

struct SoundProfile: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let loopPrefix: String
    let idleRPM: Double
    let maxRPM: Double
    let playbackKind: SoundPlaybackKind
    /// Synth only: pitch at display idle (deep rumble, usually below idleRPM).
    let pitchIdleRPM: Double?
    /// Synth only: display redline maps to this RPM for pitch (volume/timbre still use maxRPM).
    let pitchMaxRPM: Double?

    init(
        id: String,
        name: String,
        loopPrefix: String,
        idleRPM: Double,
        maxRPM: Double,
        playbackKind: SoundPlaybackKind,
        pitchIdleRPM: Double? = nil,
        pitchMaxRPM: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.loopPrefix = loopPrefix
        self.idleRPM = idleRPM
        self.maxRPM = maxRPM
        self.playbackKind = playbackKind
        self.pitchIdleRPM = pitchIdleRPM
        self.pitchMaxRPM = pitchMaxRPM
    }

    var isSynthesized: Bool {
        if case .synthesized = playbackKind { return true }
        return false
    }

    var cylinderCount: Int? {
        if case .synthesized(let cylinders) = playbackKind { return cylinders }
        return nil
    }

    var factorySynthPatch: SynthPatch? {
        SynthPatch.factoryPatch(for: id)
    }

    func resourceName(for tier: EngineLoopTier) -> String {
        "\(loopPrefix)_\(tier.rawValue)"
    }
}

enum SoundPackCatalog {
    static let tundraTRD: [SoundProfile] = [
        SoundProfile(
            id: "trd-v6-balanced",
            name: "TRD V6 Balanced",
            loopPrefix: "trd_v6_balanced",
            idleRPM: 750,
            maxRPM: 6200,
            playbackKind: .sampleLoops
        ),
        SoundProfile(
            id: "trd-v6-aggressive",
            name: "TRD V6 Aggressive",
            loopPrefix: "trd_v6_aggressive",
            idleRPM: 800,
            maxRPM: 6500,
            playbackKind: .sampleLoops
        ),
        SoundProfile(
            id: "trd-v8-deep",
            name: "TRD V8 Deep",
            loopPrefix: "trd_v8_deep",
            idleRPM: 650,
            maxRPM: 5800,
            playbackKind: .sampleLoops
        ),
        SoundProfile(
            id: "synth-v6",
            name: "Synth V6",
            loopPrefix: "",
            idleRPM: 750,
            maxRPM: 6200,
            playbackKind: .synthesized(cylinders: 6)
        ),
        SoundProfile(
            id: "synth-v8",
            name: "Synth V8",
            loopPrefix: "",
            idleRPM: 500,
            maxRPM: 6500,
            playbackKind: .synthesized(cylinders: 8),
            pitchIdleRPM: 240,
            pitchMaxRPM: 650
        ),
        SoundProfile(
            id: "synth-v8-v2",
            name: "Synth V8 v2",
            loopPrefix: "",
            idleRPM: 1050,
            maxRPM: 6500,
            playbackKind: .synthesized(cylinders: 8),
            pitchIdleRPM: 380,
            pitchMaxRPM: 2000
        ),
    ]

    static var defaultProfile: SoundProfile {
        tundraTRD.first(where: { $0.id == "synth-v8" }) ?? tundraTRD[0]
    }

    static func sampleURL(for profile: SoundProfile, tier: EngineLoopTier) -> URL? {
        Bundle.main.url(
            forResource: profile.resourceName(for: tier),
            withExtension: "wav"
        )
    }
}
