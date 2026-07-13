import AVFoundation
import Foundation

/// Bass-only procedural engine synthesizer — sub-harmonic rumble, no treble.
final class EngineSynthesizer: @unchecked Sendable {
    struct Parameters: Sendable {
        var rpm: Double = 750
        var throttle: Double = 0
        var masterVolume: Float = 0.8
        var patch = SynthPatch.default
    }

    struct Diagnostics: Sendable {
        var pitchRPM: Double = 0
        var crankHz: Double = 0
        var firingHz: Double = 0
    }

    private final class RenderContext: @unchecked Sendable {
        let lock = NSLock()
        var params = Parameters()
        var firingPhase = 0.0
        var crankPhase = 0.0
        var smoothedRPM = 750.0
        var smoothedThrottle = 0.0
        var lowpassA = 0.0
        var lowpassB = 0.0
        var rumbleDrift = 0.0
        var rumbleDriftTarget = 0.0
        var rumbleNoise = 0.0
        var diagnostics = Diagnostics()
        let cylinders: Int
        let sampleRate: Double

        init(cylinders: Int, sampleRate: Double) {
            self.cylinders = cylinders
            self.sampleRate = sampleRate
        }

        func pitchRPM(for displayRPM: Double, patch: SynthPatch) -> Double {
            let idle = patch.displayIdleRPM
            let range = max(patch.displayMaxRPM - idle, 1)
            let norm = min(max((displayRPM - idle) / range, 0), 1)
            let pitchSpan = max(patch.pitchMaxRPM - patch.pitchIdleRPM, 1)
            return patch.pitchIdleRPM + norm * pitchSpan
        }

        func render(into buffer: UnsafeMutablePointer<Float>, frameCount: AVAudioFrameCount) {
            lock.lock()
            let targets = params
            lock.unlock()

            let patch = targets.patch

            smoothedRPM += (targets.rpm - smoothedRPM) * patch.rpmSmoothing
            smoothedThrottle += (targets.throttle - smoothedThrottle) * patch.throttleSmoothing

            let rpmRange = max(patch.displayMaxRPM - patch.displayIdleRPM, 1)
            let rpmNorm = min(max((smoothedRPM - patch.displayIdleRPM) / rpmRange, 0), 1)
            let throttleNorm = min(max(smoothedThrottle / 100.0, 0), 1)

            let pitchRPM = pitchRPM(for: smoothedRPM, patch: patch)
            let crankHz = max(patch.minCrankHz, pitchRPM / 60.0)
            let firingHz = max(patch.minFiringHz, crankHz * Double(cylinders) / 2.0)

            diagnostics = Diagnostics(pitchRPM: pitchRPM, crankHz: crankHz, firingHz: firingHz)

            let cutoffHz = patch.filterCutoffBase
                + rpmNorm * patch.filterCutoffRPMGain
                + throttleNorm * patch.filterCutoffThrottleGain
            let lowpassAlpha = 1.0 - exp(-2.0 * Double.pi * cutoffHz / sampleRate)

            let revMix = min(max(pow(rpmNorm, patch.revMixPower) * patch.revMixScale, 0), 1)
            let variation = patch.rumbleVariation

            if variation > 0.0001 {
                rumbleDriftTarget = rumbleDriftTarget * 0.985 + Double.random(in: -1...1) * 0.015
                rumbleDrift += (rumbleDriftTarget - rumbleDrift) * 0.008 * variation
            } else {
                rumbleDrift *= 0.99
            }

            for frame in 0..<Int(frameCount) {
                if variation > 0.0001 {
                    rumbleNoise = rumbleNoise * 0.9992 + Double.random(in: -1...1) * 0.0008 * variation
                }

                let crankRate = crankHz * (1.0 + rumbleDrift * 0.06 * variation)
                crankPhase += crankRate / sampleRate
                if crankPhase >= 1.0 { crankPhase -= floor(crankPhase) }

                firingPhase += firingHz / sampleRate
                if firingPhase >= 1.0 { firingPhase -= floor(firingPhase) }

                let crankTheta = 2.0 * Double.pi * crankPhase
                let firingTheta = 2.0 * Double.pi * firingPhase
                let crankWobble = rumbleNoise * 0.4 * variation

                let crankBass = patch.rumbleEmphasis * (1.0 + rumbleNoise * 0.18 * variation) * (
                    patch.crank125Gain * sin(crankTheta * 0.125 + crankWobble) +
                    patch.crank0625Gain * sin(crankTheta * 0.0625 - crankWobble * 0.5) +
                    patch.crank25Gain * sin(crankTheta * 0.25 + crankWobble * 0.3) +
                    patch.crank50Gain * sin(crankTheta * 0.5)
                )

                let firingBass = patch.firingEmphasis * (
                    patch.firing125Gain * sin(firingTheta * 0.125) +
                    patch.firing0625Gain * sin(firingTheta * 0.0625) +
                    patch.firing25Gain * sin(firingTheta * 0.25) +
                    patch.firing50Gain * sin(firingTheta * 0.5)
                )

                let revBass = revMix * (
                    patch.firingEmphasis * patch.revFiring50Gain * sin(firingTheta * 0.5) +
                    patch.rumbleEmphasis * patch.revCrank50Gain * sin(crankTheta * 0.5)
                )

                let raw = crankBass + firingBass + revBass
                let intensity = patch.baseIntensity
                    + rpmNorm * patch.rpmIntensityGain
                    + throttleNorm * patch.throttleIntensityGain
                let amplified = raw * intensity

                lowpassA += lowpassAlpha * (amplified - lowpassA)
                lowpassB += lowpassAlpha * (lowpassA - lowpassB)
                buffer[frame] = Float(lowpassB * Double(targets.masterVolume) * patch.outputGain)
            }
        }
    }

    private let engine = AVAudioEngine()
    private let sourceNode: AVAudioSourceNode
    private let context: RenderContext

    init(cylinders: Int) {
        let sessionRate = AVAudioSession.sharedInstance().sampleRate
        let sampleRate = sessionRate > 0 ? sessionRate : 48_000
        context = RenderContext(cylinders: cylinders, sampleRate: sampleRate)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        sourceNode = AVAudioSourceNode(format: format) { [context] isSilence, _, frameCount, outputData in
            let buffers = UnsafeMutableAudioBufferListPointer(outputData)
            guard let first = buffers.first,
                  let ptr = first.mData?.assumingMemoryBound(to: Float.self) else {
                return kAudioUnitErr_InvalidParameter
            }
            context.render(into: ptr, frameCount: frameCount)
            isSilence.pointee = false
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
    }

    func configure(patch: SynthPatch, masterVolume: Float) {
        context.lock.lock()
        context.params.patch = patch
        context.params.masterVolume = masterVolume
        context.lock.unlock()
    }

    func applyPatch(_ patch: SynthPatch) {
        context.lock.lock()
        context.params.patch = patch
        context.lock.unlock()
    }

    func update(rpm: Double, throttle: Double, masterVolume: Float) {
        context.lock.lock()
        context.params.rpm = rpm
        context.params.throttle = throttle
        context.params.masterVolume = masterVolume
        context.lock.unlock()
    }

    func snapshotDiagnostics() -> Diagnostics {
        context.diagnostics
    }

    func start() throws {
        engine.prepare()
        if !engine.isRunning {
            try engine.start()
        }
    }

    func stop() {
        engine.pause()
        context.lock.lock()
        context.firingPhase = 0
        context.crankPhase = 0
        context.lowpassA = 0
        context.lowpassB = 0
        context.rumbleDrift = 0
        context.rumbleDriftTarget = 0
        context.rumbleNoise = 0
        context.smoothedRPM = context.params.rpm
        context.smoothedThrottle = context.params.throttle
        context.lock.unlock()
    }
}
