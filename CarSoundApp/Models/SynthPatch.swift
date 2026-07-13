import Foundation

/// All tunable synthesizer parameters — editable from the Synth Tuner UI.
struct SynthPatch: Codable, Equatable, Sendable {
    // MARK: Pitch & display range

    var pitchIdleRPM: Double = 240
    var pitchMaxRPM: Double = 650
    var displayIdleRPM: Double = 500
    var displayMaxRPM: Double = 6500

    // MARK: Character (master emphasis)

    /// Scales all crank / rumble layers.
    var rumbleEmphasis: Double = 1.0
    /// Scales all cylinder firing layers.
    var firingEmphasis: Double = 1.0
    /// Slow random drift and texture on rumble layers (0 = steady, 1 = maximum variation).
    var rumbleVariation: Double = 0

    // MARK: Crank layer gains (sub-harmonics of crank rate)

    var crank0625Gain: Double = 0.42
    var crank125Gain: Double = 0.48
    var crank25Gain: Double = 0.36
    var crank50Gain: Double = 0.26

    // MARK: Firing layer gains (sub-harmonics of firing rate)

    var firing0625Gain: Double = 0.40
    var firing125Gain: Double = 0.44
    var firing25Gain: Double = 0.34
    var firing50Gain: Double = 0.32

    // MARK: Rev-only layers (scale with RPM)

    var revFiring50Gain: Double = 0.16
    var revCrank50Gain: Double = 0.10

    // MARK: Dynamics

    var baseIntensity: Double = 0.74
    var rpmIntensityGain: Double = 0.18
    var throttleIntensityGain: Double = 0.14
    var outputGain: Double = 0.58

    // MARK: Low-pass filter (Hz)

    var filterCutoffBase: Double = 48
    var filterCutoffRPMGain: Double = 42
    var filterCutoffThrottleGain: Double = 10

    // MARK: Smoothing (0…1 per audio buffer)

    var rpmSmoothing: Double = 0.12
    var throttleSmoothing: Double = 0.18

    // MARK: Frequency floors (Hz)

    var minCrankHz: Double = 2.0
    var minFiringHz: Double = 3.0

    // MARK: Rev blend curve

    var revMixPower: Double = 1.6
    var revMixScale: Double = 2.8

    static let `default` = SynthPatch()

    init(
        pitchIdleRPM: Double = 240,
        pitchMaxRPM: Double = 650,
        displayIdleRPM: Double = 500,
        displayMaxRPM: Double = 6500,
        rumbleEmphasis: Double = 1.0,
        firingEmphasis: Double = 1.0,
        rumbleVariation: Double = 0,
        crank0625Gain: Double = 0.42,
        crank125Gain: Double = 0.48,
        crank25Gain: Double = 0.36,
        crank50Gain: Double = 0.26,
        firing0625Gain: Double = 0.40,
        firing125Gain: Double = 0.44,
        firing25Gain: Double = 0.34,
        firing50Gain: Double = 0.32,
        revFiring50Gain: Double = 0.16,
        revCrank50Gain: Double = 0.10,
        baseIntensity: Double = 0.74,
        rpmIntensityGain: Double = 0.18,
        throttleIntensityGain: Double = 0.14,
        outputGain: Double = 0.58,
        filterCutoffBase: Double = 48,
        filterCutoffRPMGain: Double = 42,
        filterCutoffThrottleGain: Double = 10,
        rpmSmoothing: Double = 0.12,
        throttleSmoothing: Double = 0.18,
        minCrankHz: Double = 2.0,
        minFiringHz: Double = 3.0,
        revMixPower: Double = 1.6,
        revMixScale: Double = 2.8
    ) {
        self.pitchIdleRPM = pitchIdleRPM
        self.pitchMaxRPM = pitchMaxRPM
        self.displayIdleRPM = displayIdleRPM
        self.displayMaxRPM = displayMaxRPM
        self.rumbleEmphasis = rumbleEmphasis
        self.firingEmphasis = firingEmphasis
        self.rumbleVariation = rumbleVariation
        self.crank0625Gain = crank0625Gain
        self.crank125Gain = crank125Gain
        self.crank25Gain = crank25Gain
        self.crank50Gain = crank50Gain
        self.firing0625Gain = firing0625Gain
        self.firing125Gain = firing125Gain
        self.firing25Gain = firing25Gain
        self.firing50Gain = firing50Gain
        self.revFiring50Gain = revFiring50Gain
        self.revCrank50Gain = revCrank50Gain
        self.baseIntensity = baseIntensity
        self.rpmIntensityGain = rpmIntensityGain
        self.throttleIntensityGain = throttleIntensityGain
        self.outputGain = outputGain
        self.filterCutoffBase = filterCutoffBase
        self.filterCutoffRPMGain = filterCutoffRPMGain
        self.filterCutoffThrottleGain = filterCutoffThrottleGain
        self.rpmSmoothing = rpmSmoothing
        self.throttleSmoothing = throttleSmoothing
        self.minCrankHz = minCrankHz
        self.minFiringHz = minFiringHz
        self.revMixPower = revMixPower
        self.revMixScale = revMixScale
    }

    /// Jeff's tuned V8 patch (v2) — factory starting point for the Synth V8 v2 profile.
    static let jeffV2 = SynthPatch(
        pitchIdleRPM: 380,
        pitchMaxRPM: 2000,
        displayIdleRPM: 1050,
        displayMaxRPM: 6500,
        rumbleEmphasis: 1.0,
        firingEmphasis: 1.25,
        crank0625Gain: 0.25,
        crank125Gain: 0.48,
        crank25Gain: 0.28,
        crank50Gain: 0.34,
        firing0625Gain: 0.40,
        firing125Gain: 0.44,
        firing25Gain: 0.58,
        firing50Gain: 0.41,
        revFiring50Gain: 0.16,
        revCrank50Gain: 0.10,
        baseIntensity: 1.2,
        rpmIntensityGain: 0.38,
        throttleIntensityGain: 0.14,
        outputGain: 0.58,
        filterCutoffBase: 46,
        filterCutoffRPMGain: 30,
        filterCutoffThrottleGain: 11,
        rpmSmoothing: 0.10,
        throttleSmoothing: 0.18,
        minCrankHz: 2.0,
        minFiringHz: 3.0,
        revMixPower: 1.6,
        revMixScale: 2.8
    )

    static func factoryPatch(for profileID: String) -> SynthPatch? {
        switch profileID {
        case "synth-v8-v2":
            return .jeffV2
        default:
            return nil
        }
    }

    static func forProfile(_ profile: SoundProfile) -> SynthPatch {
        if let factory = factoryPatch(for: profile.id) {
            return factory
        }

        var patch = SynthPatch.default
        patch.displayIdleRPM = profile.idleRPM
        patch.displayMaxRPM = profile.maxRPM
        if let pitchIdle = profile.pitchIdleRPM { patch.pitchIdleRPM = pitchIdle }
        if let pitchMax = profile.pitchMaxRPM { patch.pitchMaxRPM = pitchMax }
        return patch
    }

    private enum CodingKeys: String, CodingKey {
        case pitchIdleRPM, pitchMaxRPM, displayIdleRPM, displayMaxRPM
        case rumbleEmphasis, firingEmphasis, rumbleVariation
        case crank0625Gain, crank125Gain, crank25Gain, crank50Gain
        case firing0625Gain, firing125Gain, firing25Gain, firing50Gain
        case revFiring50Gain, revCrank50Gain
        case baseIntensity, rpmIntensityGain, throttleIntensityGain, outputGain
        case filterCutoffBase, filterCutoffRPMGain, filterCutoffThrottleGain
        case rpmSmoothing, throttleSmoothing
        case minCrankHz, minFiringHz
        case revMixPower, revMixScale
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        pitchIdleRPM = try c.decodeIfPresent(Double.self, forKey: .pitchIdleRPM) ?? 240
        pitchMaxRPM = try c.decodeIfPresent(Double.self, forKey: .pitchMaxRPM) ?? 650
        displayIdleRPM = try c.decodeIfPresent(Double.self, forKey: .displayIdleRPM) ?? 500
        displayMaxRPM = try c.decodeIfPresent(Double.self, forKey: .displayMaxRPM) ?? 6500
        rumbleEmphasis = try c.decodeIfPresent(Double.self, forKey: .rumbleEmphasis) ?? 1.0
        firingEmphasis = try c.decodeIfPresent(Double.self, forKey: .firingEmphasis) ?? 1.0
        rumbleVariation = try c.decodeIfPresent(Double.self, forKey: .rumbleVariation) ?? 0
        crank0625Gain = try c.decodeIfPresent(Double.self, forKey: .crank0625Gain) ?? 0.42
        crank125Gain = try c.decodeIfPresent(Double.self, forKey: .crank125Gain) ?? 0.48
        crank25Gain = try c.decodeIfPresent(Double.self, forKey: .crank25Gain) ?? 0.36
        crank50Gain = try c.decodeIfPresent(Double.self, forKey: .crank50Gain) ?? 0.26
        firing0625Gain = try c.decodeIfPresent(Double.self, forKey: .firing0625Gain) ?? 0.40
        firing125Gain = try c.decodeIfPresent(Double.self, forKey: .firing125Gain) ?? 0.44
        firing25Gain = try c.decodeIfPresent(Double.self, forKey: .firing25Gain) ?? 0.34
        firing50Gain = try c.decodeIfPresent(Double.self, forKey: .firing50Gain) ?? 0.32
        revFiring50Gain = try c.decodeIfPresent(Double.self, forKey: .revFiring50Gain) ?? 0.16
        revCrank50Gain = try c.decodeIfPresent(Double.self, forKey: .revCrank50Gain) ?? 0.10
        baseIntensity = try c.decodeIfPresent(Double.self, forKey: .baseIntensity) ?? 0.74
        rpmIntensityGain = try c.decodeIfPresent(Double.self, forKey: .rpmIntensityGain) ?? 0.18
        throttleIntensityGain = try c.decodeIfPresent(Double.self, forKey: .throttleIntensityGain) ?? 0.14
        outputGain = try c.decodeIfPresent(Double.self, forKey: .outputGain) ?? 0.58
        filterCutoffBase = try c.decodeIfPresent(Double.self, forKey: .filterCutoffBase) ?? 48
        filterCutoffRPMGain = try c.decodeIfPresent(Double.self, forKey: .filterCutoffRPMGain) ?? 42
        filterCutoffThrottleGain = try c.decodeIfPresent(Double.self, forKey: .filterCutoffThrottleGain) ?? 10
        rpmSmoothing = try c.decodeIfPresent(Double.self, forKey: .rpmSmoothing) ?? 0.12
        throttleSmoothing = try c.decodeIfPresent(Double.self, forKey: .throttleSmoothing) ?? 0.18
        minCrankHz = try c.decodeIfPresent(Double.self, forKey: .minCrankHz) ?? 2.0
        minFiringHz = try c.decodeIfPresent(Double.self, forKey: .minFiringHz) ?? 3.0
        revMixPower = try c.decodeIfPresent(Double.self, forKey: .revMixPower) ?? 1.6
        revMixScale = try c.decodeIfPresent(Double.self, forKey: .revMixScale) ?? 2.8
    }
}
