import AVFoundation
import Foundation

/// Bass-focused engine synthesizer — optional idle WAV base pitched with RPM, plus procedural layers.
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
        var sampleRate: Double = 1
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

        /// Mono float loop of the idle base sample (engine sample rate).
        var baseLoop: [Float] = []
        var baseReadPosition = 0.0
        /// Display RPM where the base loop plays at 1.0×.
        var baseReferenceRPM: Double = 720
        var usesBaseSample = false

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
            let loop = baseLoop
            let referenceRPM = baseReferenceRPM
            let hasSample = usesBaseSample && !loop.isEmpty
            lock.unlock()

            let patch = targets.patch
            let loopCount = loop.count

            smoothedRPM += (targets.rpm - smoothedRPM) * patch.rpmSmoothing
            smoothedThrottle += (targets.throttle - smoothedThrottle) * patch.throttleSmoothing

            let rpmRange = max(patch.displayMaxRPM - patch.displayIdleRPM, 1)
            let rpmNorm = min(max((smoothedRPM - patch.displayIdleRPM) / rpmRange, 0), 1)
            let throttleNorm = min(max(smoothedThrottle / 100.0, 0), 1)

            let pitchRPM = pitchRPM(for: smoothedRPM, patch: patch)
            let crankHz = max(patch.minCrankHz, pitchRPM / 60.0)
            let firingHz = max(patch.minFiringHz, crankHz * Double(cylinders) / 2.0)

            let variation = patch.rumbleVariation
            if variation > 0.0001 {
                rumbleDriftTarget = rumbleDriftTarget * 0.985 + Double.random(in: -1...1) * 0.015
                rumbleDrift += (rumbleDriftTarget - rumbleDrift) * 0.008 * variation
            } else {
                rumbleDrift *= 0.99
            }

            // Sample rate follows pitch RPM (tuner pitch idle/max + display range),
            // with baseReferenceRPM as the rate=1.0 acoustic anchor for the WAV.
            var samplePlaybackRate = 1.0
            if hasSample, referenceRPM > 0 {
                samplePlaybackRate = min(max(pitchRPM / referenceRPM, 0.35), 4.0)
                // Rumble variation wobbles the sample playback rate so the Character knob is audible.
                samplePlaybackRate *= 1.0 + rumbleDrift * 0.05 * variation
                samplePlaybackRate = min(max(samplePlaybackRate, 0.35), 4.0)
            }

            diagnostics = Diagnostics(
                pitchRPM: pitchRPM,
                crankHz: crankHz,
                firingHz: firingHz,
                sampleRate: samplePlaybackRate
            )

            let cutoffHz = max(
                20.0,
                patch.filterCutoffBase
                    + rpmNorm * patch.filterCutoffRPMGain
                    + throttleNorm * patch.filterCutoffThrottleGain
            )
            let lowpassAlpha = 1.0 - exp(-2.0 * Double.pi * cutoffHz / sampleRate)

            let revMix = min(max(pow(rpmNorm, patch.revMixPower) * patch.revMixScale, 0), 1)

            // Dynamics apply to both sample and synth so Intensity knobs always respond.
            let intensity = patch.baseIntensity
                + rpmNorm * patch.rpmIntensityGain
                + throttleNorm * patch.throttleIntensityGain

            // With a base sample, keep the WAV as the body and the procedural layers as a
            // clearly audible overlay so Character / Crank / Firing / Rev knobs still work.
            let sampleGain: Double
            let synthGain: Double
            if hasSample {
                sampleGain = intensity * max(0.15, patch.rumbleEmphasis)
                synthGain = intensity * (
                    0.55
                        + rpmNorm * 0.70
                        + throttleNorm * 0.25
                        + max(0.0, patch.firingEmphasis - 0.5) * 0.25
                )
            } else {
                sampleGain = 0.0
                synthGain = intensity
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

                var sampleValue = 0.0
                if hasSample {
                    let index = Int(baseReadPosition)
                    let frac = baseReadPosition - Double(index)
                    let i0 = ((index % loopCount) + loopCount) % loopCount
                    let i1 = (i0 + 1) % loopCount
                    sampleValue = Double(loop[i0]) * (1.0 - frac) + Double(loop[i1]) * frac
                    // Amplitude flutter from rumble variation.
                    sampleValue *= 1.0 + rumbleNoise * 0.14 * variation
                    baseReadPosition += samplePlaybackRate
                    if baseReadPosition >= Double(loopCount) {
                        baseReadPosition = baseReadPosition.truncatingRemainder(dividingBy: Double(loopCount))
                    }
                }

                let amplified = sampleValue * sampleGain + (crankBass + firingBass + revBass) * synthGain

                lowpassA += lowpassAlpha * (amplified - lowpassA)
                lowpassB += lowpassAlpha * (lowpassA - lowpassB)
                buffer[frame] = Float(lowpassB * Double(targets.masterVolume) * patch.outputGain)
            }
        }
    }

    private let engine = AVAudioEngine()
    private let sourceNode: AVAudioSourceNode
    private let context: RenderContext

    init(cylinders: Int, baseSampleURL: URL? = nil, baseSampleReferenceRPM: Double = 720) {
        let sessionRate = AVAudioSession.sharedInstance().sampleRate
        let sampleRate = sessionRate > 0 ? sessionRate : 48_000
        context = RenderContext(cylinders: cylinders, sampleRate: sampleRate)
        context.baseReferenceRPM = baseSampleReferenceRPM

        if let baseSampleURL {
            do {
                context.baseLoop = try Self.loadMonoLoop(from: baseSampleURL, targetSampleRate: sampleRate)
                context.usesBaseSample = !context.baseLoop.isEmpty
            } catch {
                context.baseLoop = []
                context.usesBaseSample = false
            }
        }

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

    var usesBaseSample: Bool {
        context.usesBaseSample
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
        context.baseReadPosition = 0
        context.smoothedRPM = context.params.rpm
        context.smoothedThrottle = context.params.throttle
        context.lock.unlock()
    }

    private static func loadMonoLoop(from url: URL, targetSampleRate: Double) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let frameCount = AVAudioFrameCount(file.length)
        guard frameCount > 0,
              let sourceBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount) else {
            return []
        }
        try file.read(into: sourceBuffer)

        let targetFormat = AVAudioFormat(standardFormatWithSampleRate: targetSampleRate, channels: 1)!
        let converted: AVAudioPCMBuffer
        if file.processingFormat.sampleRate == targetSampleRate,
           file.processingFormat.channelCount == 1,
           file.processingFormat.commonFormat == .pcmFormatFloat32 {
            converted = sourceBuffer
        } else {
            guard let converter = AVAudioConverter(from: file.processingFormat, to: targetFormat) else {
                return []
            }
            let ratio = targetSampleRate / file.processingFormat.sampleRate
            let capacity = AVAudioFrameCount(Double(frameCount) * ratio) + 64
            guard let outBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else {
                return []
            }
            var error: NSError?
            var consumed = false
            converter.convert(to: outBuffer, error: &error) { _, outStatus in
                if consumed {
                    outStatus.pointee = .endOfStream
                    return nil
                }
                consumed = true
                outStatus.pointee = .haveData
                return sourceBuffer
            }
            if let error { throw error }
            converted = outBuffer
        }

        guard let channelData = converted.floatChannelData?[0] else { return [] }
        let count = Int(converted.frameLength)
        return Array(UnsafeBufferPointer(start: channelData, count: count))
    }
}
