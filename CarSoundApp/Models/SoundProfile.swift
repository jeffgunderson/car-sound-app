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

/// RPM anchors for crossfading idle / cruise / high sample loops.
struct SampleLoopCrossfade: Equatable, Sendable {
    /// RPM where the idle loop is loudest.
    let idlePeakRPM: Double
    /// RPM where the cruise loop is loudest.
    let cruisePeakRPM: Double
    /// RPM where the high loop is loudest.
    let highPeakRPM: Double
    /// Half-width of each loop's influence — wider = gentler transitions.
    let blendWidthRPM: Double

    static func `default`(idleRPM: Double, maxRPM: Double) -> SampleLoopCrossfade {
        let range = maxRPM - idleRPM
        return SampleLoopCrossfade(
            idlePeakRPM: idleRPM + range * 0.04,
            cruisePeakRPM: idleRPM + range * 0.22,
            highPeakRPM: idleRPM + range * 0.68,
            blendWidthRPM: max(range * 0.18, 350)
        )
    }

    /// Tuned for TRD V8 Deep — keeps the low-RPM character around ~900 RPM while easing into cruise.
    static let trdV8Deep = SampleLoopCrossfade(
        idlePeakRPM: 720,
        cruisePeakRPM: 1_350,
        highPeakRPM: 4_200,
        blendWidthRPM: 900
    )

    func referenceRPM(for tier: EngineLoopTier) -> Double {
        switch tier {
        case .idle: return idlePeakRPM
        case .cruise: return cruisePeakRPM
        case .high: return highPeakRPM
        }
    }
}

/// Native timbre center frequencies from `generate_sounds.py` — used to keep pitch aligned across tiers.
struct LoopTierTimbre: Equatable, Sendable {
    let idleHz: Double
    let cruiseHz: Double
    let highHz: Double

    static let v6Balanced = LoopTierTimbre(idleHz: 42, cruiseHz: 52, highHz: 66)
    static let v6Aggressive = LoopTierTimbre(idleHz: 46, cruiseHz: 58, highHz: 72)
    static let v8Deep = LoopTierTimbre(idleHz: 32, cruiseHz: 40, highHz: 50)

    func baseHz(for tier: EngineLoopTier) -> Double {
        switch tier {
        case .idle: return idleHz
        case .cruise: return cruiseHz
        case .high: return highHz
        }
    }
}

struct SoundProfile: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let loopPrefix: String
    let idleRPM: Double
    let maxRPM: Double
    let playbackKind: SoundPlaybackKind
    let loopCrossfade: SampleLoopCrossfade?
    let loopTierTimbre: LoopTierTimbre?
    /// Synth only: pitch at display idle (deep rumble, usually below idleRPM).
    let pitchIdleRPM: Double?
    /// Synth only: display redline maps to this RPM for pitch (volume/timbre still use maxRPM).
    let pitchMaxRPM: Double?
    /// Optional bundled WAV used as the synth idle/base loop (pitched with RPM).
    let baseSampleName: String?
    /// Display RPM at which `baseSampleName` plays at 1.0× rate.
    let baseSampleReferenceRPM: Double?

    init(
        id: String,
        name: String,
        loopPrefix: String,
        idleRPM: Double,
        maxRPM: Double,
        playbackKind: SoundPlaybackKind,
        loopCrossfade: SampleLoopCrossfade? = nil,
        loopTierTimbre: LoopTierTimbre? = nil,
        pitchIdleRPM: Double? = nil,
        pitchMaxRPM: Double? = nil,
        baseSampleName: String? = nil,
        baseSampleReferenceRPM: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.loopPrefix = loopPrefix
        self.idleRPM = idleRPM
        self.maxRPM = maxRPM
        self.playbackKind = playbackKind
        self.loopCrossfade = loopCrossfade
        self.loopTierTimbre = loopTierTimbre
        self.pitchIdleRPM = pitchIdleRPM
        self.pitchMaxRPM = pitchMaxRPM
        self.baseSampleName = baseSampleName
        self.baseSampleReferenceRPM = baseSampleReferenceRPM
    }

    var resolvedLoopCrossfade: SampleLoopCrossfade {
        loopCrossfade ?? .default(idleRPM: idleRPM, maxRPM: maxRPM)
    }

    var resolvedLoopTimbre: LoopTierTimbre {
        loopTierTimbre ?? .v6Balanced
    }

    var isSynthesized: Bool {
        if case .synthesized = playbackKind { return true }
        return false
    }

    /// Short line under the profile name in the main carousel.
    var selectionSubtitle: String {
        if isSynthesized {
            if let cylinders = cylinderCount {
                return baseSampleName != nil
                    ? "Synthesized · \(cylinders)-cyl · sample base"
                    : "Synthesized · \(cylinders)-cylinder"
            }
            return "Synthesized"
        }
        return "Sample loops · \(Int(idleRPM))–\(Int(maxRPM)) RPM"
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
            playbackKind: .sampleLoops,
            loopTierTimbre: .v6Balanced
        ),
        SoundProfile(
            id: "trd-v6-aggressive",
            name: "TRD V6 Aggressive",
            loopPrefix: "trd_v6_aggressive",
            idleRPM: 800,
            maxRPM: 6500,
            playbackKind: .sampleLoops,
            loopTierTimbre: .v6Aggressive
        ),
        SoundProfile(
            id: "trd-v8-deep",
            name: "TRD V8 Deep",
            loopPrefix: "trd_v8_deep",
            idleRPM: 650,
            maxRPM: 5800,
            playbackKind: .sampleLoops,
            loopCrossfade: .trdV8Deep,
            loopTierTimbre: .v8Deep
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
        SoundProfile(
            id: "synth-trd-v8",
            name: "Synth TRD V8",
            loopPrefix: "",
            idleRPM: 650,
            maxRPM: 5800,
            playbackKind: .synthesized(cylinders: 8),
            pitchIdleRPM: 650,
            pitchMaxRPM: 2_800,
            baseSampleName: "trd_v8_deep_idle",
            baseSampleReferenceRPM: 720
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

    static func baseSampleURL(named name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "wav")
    }
}
