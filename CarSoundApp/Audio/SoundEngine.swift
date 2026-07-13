import AVFoundation
import Foundation
import os

@MainActor
final class SoundEngine {
    private let logger = Logger(subsystem: "com.jeffgunderson.CarSoundApp", category: "SoundEngine")

    private var loopPlayers: [EngineLoopTier: AVAudioPlayer] = [:]
    private var synthesizer: EngineSynthesizer?
    private var usesSynthesizer = false
    private var isConfigured = false

    private var targetRPM: Double = 750
    private var targetThrottle: Double = 0
    private var smoothedRPM: Double = 750
    private var smoothedThrottle: Double = 0

    private var updateTimer: Timer?
    private var currentProfile: SoundProfile?
    private var masterVolume: Float = 0.8
    private var synthPatch = SynthPatch.default
    private(set) var isPlaying = false
    private(set) var debugStatus = "Idle"

    private let rpmSmoothing: Double = 0.15
    private let throttleSmoothing: Double = 0.2

    func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playback,
            mode: .default,
            options: [.mixWithOthers, .allowBluetoothA2DP]
        )
        try session.setActive(true)
        debugStatus = "Session active · \(session.category.rawValue)"
    }

    func load(profile: SoundProfile, synthPatch patchOverride: SynthPatch? = nil) throws {
        let wasPlaying = isPlaying
        stopPlayback()
        loopPlayers.removeAll()
        synthesizer = nil
        usesSynthesizer = false

        currentProfile = profile

        switch profile.playbackKind {
        case .sampleLoops:
            try loadSampleLoops(for: profile)
            debugStatus = "Loaded \(profile.name) · 3 loops"
        case .synthesized(let cylinders):
            let synth = EngineSynthesizer(cylinders: cylinders)
            synthPatch = patchOverride ?? SynthPatch.forProfile(profile)
            synth.configure(patch: synthPatch, masterVolume: masterVolume)
            synth.update(rpm: targetRPM, throttle: targetThrottle, masterVolume: masterVolume)
            synthesizer = synth
            usesSynthesizer = true
            debugStatus = "Loaded \(profile.name) · synthesizer"
            logger.info("Loaded synthesizer profile with \(cylinders) cylinders")
        }

        isConfigured = true

        if wasPlaying {
            _ = startPlayback()
        }
    }

    func setMasterVolume(_ volume: Float) {
        masterVolume = min(max(volume, 0), 1)
        if usesSynthesizer {
            synthesizer?.update(rpm: smoothedRPM, throttle: smoothedThrottle, masterVolume: masterVolume)
        } else {
            applyMixLevels()
        }
    }

    @discardableResult
    func startPlayback() -> Bool {
        guard isConfigured else {
            logger.error("startPlayback called before audio was configured")
            debugStatus = "Not configured"
            return false
        }

        if usesSynthesizer {
            guard let synthesizer else { return false }
            do {
                try synthesizer.start()
                isPlaying = true
                startUpdateTimer()
                debugStatus = String(
                    format: "Playing · synth · %.0f rpm · %.0f%% thr",
                    smoothedRPM,
                    smoothedThrottle
                )
                logger.info("Synth playback started")
                return true
            } catch {
                logger.error("Synth start failed: \(error.localizedDescription)")
                debugStatus = "Synth start failed"
                return false
            }
        }

        guard !loopPlayers.isEmpty else {
            debugStatus = "Not configured"
            return false
        }

        applyMixLevels()

        var startedAny = false
        for player in loopPlayers.values {
            if player.play() {
                startedAny = true
            }
        }

        guard startedAny else {
            logger.error("AVAudioPlayer.play() returned false for all loops")
            debugStatus = "play() returned false"
            return false
        }

        isPlaying = true
        startUpdateTimer()
        logger.info("Sample playback started (crossfade mode)")
        return true
    }

    func stopPlayback() {
        isPlaying = false
        stopUpdateTimer()

        if usesSynthesizer {
            synthesizer?.stop()
        } else {
            for player in loopPlayers.values {
                player.stop()
                player.currentTime = 0
            }
        }

        debugStatus = "Stopped"
    }

    func update(vehicleState: VehicleState) {
        targetRPM = vehicleState.rpm
        targetThrottle = vehicleState.throttle
    }

    func setSynthPatch(_ patch: SynthPatch) {
        synthPatch = patch
        synthesizer?.applyPatch(patch)
    }

    func synthDiagnostics() -> EngineSynthesizer.Diagnostics? {
        synthesizer?.snapshotDiagnostics()
    }

    var isSynthesizerActive: Bool {
        usesSynthesizer
    }

    private func loadSampleLoops(for profile: SoundProfile) throws {
        for tier in EngineLoopTier.allCases {
            guard let url = SoundPackCatalog.sampleURL(for: profile, tier: tier) else {
                logger.error("Missing sample: \(profile.resourceName(for: tier)).wav")
                throw SoundEngineError.missingSample(profile.resourceName(for: tier))
            }

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.enableRate = true
            player.rate = 1.0
            guard player.prepareToPlay() else {
                throw SoundEngineError.playerPrepareFailed(profile.resourceName(for: tier))
            }
            loopPlayers[tier] = player
            logger.info("Loaded \(tier.rawValue) loop from \(url.lastPathComponent)")
        }
    }

    private func startUpdateTimer() {
        stopUpdateTimer()
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        updateTimer = timer
    }

    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func tick() {
        smoothedRPM += (targetRPM - smoothedRPM) * rpmSmoothing
        smoothedThrottle += (targetThrottle - smoothedThrottle) * throttleSmoothing

        if usesSynthesizer {
            synthesizer?.update(rpm: smoothedRPM, throttle: smoothedThrottle, masterVolume: masterVolume)
            if isPlaying, let synth = synthesizer {
                let d = synth.snapshotDiagnostics()
                debugStatus = String(
                    format: "Playing · synth · %.0f rpm · %.0f%% thr · pitch %.0f · %.0f/%.0f Hz",
                    smoothedRPM,
                    smoothedThrottle,
                    d.pitchRPM,
                    d.crankHz,
                    d.firingHz
                )
            }
        } else {
            applyMixLevels()
        }
    }

    private func applyMixLevels() {
        guard let profile = currentProfile else { return }

        let rpmRange = profile.maxRPM - profile.idleRPM
        let normalizedRPM = rpmRange > 0
            ? (smoothedRPM - profile.idleRPM) / rpmRange
            : 0
        let clampedRPM = min(max(normalizedRPM, 0), 1)

        let throttleFactor = smoothedThrottle / 100.0
        let intensity = Float(0.6 + clampedRPM * 0.3 + throttleFactor * 0.4)
        let master = intensity * masterVolume

        let weights = crossfadeWeights(normalizedRPM: clampedRPM)

        for tier in EngineLoopTier.allCases {
            guard let player = loopPlayers[tier] else { continue }
            player.rate = 1.0
            player.volume = (weights[tier] ?? 0) * master
        }

        if isPlaying {
            let idlePct = Int((weights[.idle] ?? 0) * 100)
            let cruisePct = Int((weights[.cruise] ?? 0) * 100)
            let highPct = Int((weights[.high] ?? 0) * 100)
            debugStatus = "Playing · \(Int(smoothedRPM)) rpm · \(Int(smoothedThrottle))% thr · mix \(idlePct)/\(cruisePct)/\(highPct)"
        }
    }

    private func crossfadeWeights(normalizedRPM: Double) -> [EngineLoopTier: Float] {
        let n = normalizedRPM

        let idle = fadeOut(n, start: 0.0, end: 0.35)
        let high = fadeIn(n, start: 0.55, end: 0.85)
        var cruise = max(0.0, 1.0 - idle - high)

        if n >= 0.25 && n <= 0.75 {
            cruise = max(cruise, 0.35)
        }

        let sum = idle + cruise + high
        guard sum > 0.001 else {
            return [.idle: 0, .cruise: 1, .high: 0]
        }

        return [
            .idle: Float(idle / sum),
            .cruise: Float(cruise / sum),
            .high: Float(high / sum),
        ]
    }

    private func fadeOut(_ value: Double, start: Double, end: Double) -> Double {
        if value <= start { return 1.0 }
        if value >= end { return 0.0 }
        return 1.0 - (value - start) / (end - start)
    }

    private func fadeIn(_ value: Double, start: Double, end: Double) -> Double {
        if value <= start { return 0.0 }
        if value >= end { return 1.0 }
        return (value - start) / (end - start)
    }
}

enum SoundEngineError: LocalizedError {
    case missingSample(String)
    case playerPrepareFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingSample(let name):
            return "Missing bundled sound sample: \(name).wav. Run `python3 scripts/generate_sounds.py` then rebuild."
        case .playerPrepareFailed(let name):
            return "Could not prepare audio sample: \(name).wav"
        }
    }
}
