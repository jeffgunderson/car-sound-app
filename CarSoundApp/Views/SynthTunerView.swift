import SwiftUI

struct SynthTunerView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        Form {
            if !viewModel.selectedProfile.isSynthesized {
                ContentUnavailableView(
                    "Synth Profile Required",
                    systemImage: "waveform",
                    description: Text("Select a synth profile on the main screen to tune the engine.")
                )
            } else {
                Section {
                    if viewModel.isPlaying {
                        let d = viewModel.synthDiagnostics
                        LabeledContent("Pitch RPM", value: String(format: "%.0f", d.pitchRPM))
                        LabeledContent("Crank Hz", value: String(format: "%.1f", d.crankHz))
                        LabeledContent("Firing Hz", value: String(format: "%.1f", d.firingHz))
                    } else {
                        Text("Press Play on the main screen to hear changes in real time.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Live Output")
                } footer: {
                    Text("Pitch RPM is the acoustic RPM used for sound. Crank Hz is crankshaft speed; firing Hz is how often cylinders pulse.")
                }

                Section {
                    SynthKnob(
                        "Rumble emphasis",
                        description: "Overall volume of the deep crank rumble — the slow shaking you feel more than hear.",
                        value: $viewModel.synthPatch.rumbleEmphasis,
                        range: 0...3,
                        step: 0.05
                    )
                    SynthKnob(
                        "Firing emphasis",
                        description: "Overall volume of the cylinder firing pulse — the rhythmic beat layered on top of rumble.",
                        value: $viewModel.synthPatch.firingEmphasis,
                        range: 0...3,
                        step: 0.05
                    )
                    SynthKnob(
                        "Rumble variation",
                        description: "Adds slow random drift to the rumble so it feels less perfectly steady. Try 0.2–0.5 for subtle organic idle.",
                        value: $viewModel.synthPatch.rumbleVariation,
                        range: 0...1,
                        step: 0.05
                    )
                } header: {
                    Text("Character")
                }

                Section {
                    SynthKnob(
                        "Pitch idle RPM",
                        description: "How low the tone sounds at idle. Lower = deeper rumble. This is acoustic pitch, not the slider RPM.",
                        value: $viewModel.synthPatch.pitchIdleRPM,
                        range: 80...800,
                        step: 10
                    )
                    SynthKnob(
                        "Pitch max RPM",
                        description: "How high the tone reaches at redline. Maps the top of the RPM slider to this acoustic pitch.",
                        value: $viewModel.synthPatch.pitchMaxRPM,
                        range: 300...2000,
                        step: 10
                    )
                    SynthKnob(
                        "Display idle RPM",
                        description: "Where the RPM slider considers “idle” for volume and blend calculations (0% of rev range).",
                        value: $viewModel.synthPatch.displayIdleRPM,
                        range: 400...1200,
                        step: 50
                    )
                    SynthKnob(
                        "Display max RPM",
                        description: "Where the RPM slider hits 100% of the rev range for volume and blend.",
                        value: $viewModel.synthPatch.displayMaxRPM,
                        range: 3000...8000,
                        step: 100
                    )
                } header: {
                    Text("Pitch & Range")
                } footer: {
                    Text("Pitch controls how the engine sounds. Display range controls how the RPM slider maps to that sound.")
                }

                Section {
                    SynthKnob(
                        "0.0625× gain",
                        description: "Ultra-deep sub layer — very slow oscillation below the main rumble.",
                        value: $viewModel.synthPatch.crank0625Gain,
                        range: 0...1,
                        step: 0.01
                    )
                    SynthKnob(
                        "0.125× gain",
                        description: "Deep sub-bass tied to crank speed — foundation of the idle shake.",
                        value: $viewModel.synthPatch.crank125Gain,
                        range: 0...1,
                        step: 0.01
                    )
                    SynthKnob(
                        "0.25× gain",
                        description: "Low bass body from crank rotation — adds thickness to idle.",
                        value: $viewModel.synthPatch.crank25Gain,
                        range: 0...1,
                        step: 0.01
                    )
                    SynthKnob(
                        "0.5× gain",
                        description: "Upper bass from crank — more audible on phone speakers.",
                        value: $viewModel.synthPatch.crank50Gain,
                        range: 0...1,
                        step: 0.01
                    )
                } header: {
                    Text("Crank Layers")
                } footer: {
                    Text("These are sub-harmonics of crankshaft speed (RPM ÷ 60). Lower multipliers = deeper, slower rumble.")
                }

                Section {
                    SynthKnob(
                        "0.0625× gain",
                        description: "Deepest cylinder pulse layer — slow throb under the firing beat.",
                        value: $viewModel.synthPatch.firing0625Gain,
                        range: 0...1,
                        step: 0.01
                    )
                    SynthKnob(
                        "0.125× gain",
                        description: "Low firing pulse — each cylinder’s contribution at sub-bass.",
                        value: $viewModel.synthPatch.firing125Gain,
                        range: 0...1,
                        step: 0.01
                    )
                    SynthKnob(
                        "0.25× gain",
                        description: "Mid-bass firing texture — where the “engine beat” starts to be felt.",
                        value: $viewModel.synthPatch.firing25Gain,
                        range: 0...1,
                        step: 0.01
                    )
                    SynthKnob(
                        "0.5× gain",
                        description: "Loudest firing layer — the main cylinder pulse you hear at idle.",
                        value: $viewModel.synthPatch.firing50Gain,
                        range: 0...1,
                        step: 0.01
                    )
                } header: {
                    Text("Firing Layers")
                } footer: {
                    Text("Sub-harmonics of cylinder firing rate (crank Hz × cylinders ÷ 2). This is the pulsing “ba-dum” of combustion.")
                }

                Section {
                    SynthKnob(
                        "0.5× firing gain",
                        description: "Extra firing punch that fades in as RPM climbs.",
                        value: $viewModel.synthPatch.revFiring50Gain,
                        range: 0...0.5,
                        step: 0.01
                    )
                    SynthKnob(
                        "0.5× crank gain",
                        description: "Extra crank rumble that fades in at high RPM.",
                        value: $viewModel.synthPatch.revCrank50Gain,
                        range: 0...0.5,
                        step: 0.01
                    )
                    SynthKnob(
                        "Rev mix power",
                        description: "How sharply rev layers kick in. Higher = stays quiet longer, then ramps up faster.",
                        value: $viewModel.synthPatch.revMixPower,
                        range: 0.5...3,
                        step: 0.1
                    )
                    SynthKnob(
                        "Rev mix scale",
                        description: "How much of the rev layers you hear at full RPM. Higher = more high-RPM character.",
                        value: $viewModel.synthPatch.revMixScale,
                        range: 0.5...5,
                        step: 0.1
                    )
                } header: {
                    Text("Rev Layers")
                } footer: {
                    Text("Extra bass layers that only appear as you rev up — shapes the transition from idle to wide open.")
                }

                Section {
                    SynthKnob(
                        "Base intensity",
                        description: "Overall loudness at idle regardless of RPM or throttle.",
                        value: $viewModel.synthPatch.baseIntensity,
                        range: 0...1.5,
                        step: 0.01
                    )
                    SynthKnob(
                        "RPM intensity",
                        description: "How much louder the engine gets as RPM rises.",
                        value: $viewModel.synthPatch.rpmIntensityGain,
                        range: 0...1,
                        step: 0.01
                    )
                    SynthKnob(
                        "Throttle intensity",
                        description: "How much louder the engine gets when you press the throttle.",
                        value: $viewModel.synthPatch.throttleIntensityGain,
                        range: 0...1,
                        step: 0.01
                    )
                    SynthKnob(
                        "Output gain",
                        description: "Final volume multiplier for this synth patch, before master volume.",
                        value: $viewModel.synthPatch.outputGain,
                        range: 0...1.5,
                        step: 0.01
                    )
                } header: {
                    Text("Dynamics")
                }

                Section {
                    SynthKnob(
                        "Cutoff base (Hz)",
                        description: "Low-pass filter at idle — lower values keep only deep bass; higher allows more low-mid.",
                        value: $viewModel.synthPatch.filterCutoffBase,
                        range: 20...120,
                        step: 1,
                        unit: " Hz"
                    )
                    SynthKnob(
                        "Cutoff + RPM (Hz)",
                        description: "How much the filter opens as RPM increases — lets more frequencies through when revving.",
                        value: $viewModel.synthPatch.filterCutoffRPMGain,
                        range: 0...150,
                        step: 1,
                        unit: " Hz"
                    )
                    SynthKnob(
                        "Cutoff + throttle (Hz)",
                        description: "How much the filter opens with throttle — slight brightness under load.",
                        value: $viewModel.synthPatch.filterCutoffThrottleGain,
                        range: 0...50,
                        step: 1,
                        unit: " Hz"
                    )
                } header: {
                    Text("Low-Pass Filter")
                } footer: {
                    Text("Cuts high frequencies to keep the sound bass-heavy. Total cutoff = base + RPM contribution + throttle contribution.")
                }

                Section {
                    SynthKnob(
                        "RPM smoothing",
                        description: "How quickly pitch follows RPM changes. Lower = slower, smoother sweeps.",
                        value: $viewModel.synthPatch.rpmSmoothing,
                        range: 0.01...0.5,
                        step: 0.01
                    )
                    SynthKnob(
                        "Throttle smoothing",
                        description: "How quickly volume follows throttle changes. Lower = less abrupt blips.",
                        value: $viewModel.synthPatch.throttleSmoothing,
                        range: 0.01...0.5,
                        step: 0.01
                    )
                } header: {
                    Text("Smoothing")
                }

                Section {
                    SynthKnob(
                        "Min crank Hz",
                        description: "Floor for crank frequency — prevents the rumble from becoming inaudibly slow at very low pitch.",
                        value: $viewModel.synthPatch.minCrankHz,
                        range: 0.5...10,
                        step: 0.5,
                        unit: " Hz"
                    )
                    SynthKnob(
                        "Min firing Hz",
                        description: "Floor for firing frequency — keeps cylinder pulses from dropping below this rate.",
                        value: $viewModel.synthPatch.minFiringHz,
                        range: 1...20,
                        step: 0.5,
                        unit: " Hz"
                    )
                } header: {
                    Text("Advanced")
                }

                Section {
                    Button(viewModel.selectedProfile.factorySynthPatch == nil
                           ? "Reset to Profile Defaults"
                           : "Reset to Factory Patch") {
                        viewModel.resetSynthPatch()
                    }
                }
            }
        }
        .navigationTitle("Synth Tuner")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.synthPatch) { _, newPatch in
            viewModel.applySynthPatch(newPatch)
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard viewModel.isPlaying else { return }
            viewModel.refreshSynthDiagnostics()
        }
    }
}

private struct SynthKnob: View {
    let label: String
    let description: String?
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String

    init(
        _ label: String,
        description: String? = nil,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        unit: String = ""
    ) {
        self.label = label
        self.description = description
        self._value = value
        self.range = range
        self.step = step
        self.unit = unit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                Spacer()
                Text(formattedValue + unit)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            if let description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Slider(value: $value, in: range, step: step)
        }
        .padding(.vertical, 2)
    }

    private var formattedValue: String {
        if step >= 1 {
            return String(format: "%.0f", value)
        }
        if step >= 0.1 {
            return String(format: "%.1f", value)
        }
        return String(format: "%.2f", value)
    }
}

#Preview {
    NavigationStack {
        SynthTunerView()
            .environment(AppViewModel())
    }
}
