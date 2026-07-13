import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class AppViewModel {
    var dataSource: DataSource = .simulator {
        didSet { persistSettings() }
    }
    var devModeEnabled = true {
        didSet { persistSettings() }
    }
    var isPlaying = false
    var audioErrorMessage: String?
    var audioDebugStatus = ""
    var masterVolume: Float = 0.8 {
        didSet {
            soundEngine.setMasterVolume(masterVolume)
            audioDebugStatus = soundEngine.debugStatus
            persistSettings()
        }
    }

    var selectedProfile: SoundProfile = SoundPackCatalog.defaultProfile
    var synthPatch: SynthPatch = SynthPatch.default
    var synthDiagnostics = EngineSynthesizer.Diagnostics()
    var simulatorRPM: Double = 500 {
        didSet { persistSettings() }
    }
    var simulatorThrottle: Double = 0 {
        didSet { persistSettings() }
    }
    var connectionStatus: ConnectionStatus = .disconnected
    var connectionBadgeText: String {
        switch dataSource {
        case .simulator:
            return "Simulator · \(connectionStatus.displayName)"
        case .vLinker:
            return "vLinker · \(connectionStatus.displayName)"
        }
    }

    let soundProfiles = SoundPackCatalog.tundraTRD

    private let simulatorProvider = SimulatorVehicleProvider()
    private let vLinkerProvider = VLinkerProvider()
    private let soundEngine = SoundEngine()

    private var stateStreamTask: Task<Void, Never>?
    private var audioConfigured = false
    private var settingsPersistenceEnabled = false

    var simulatorProviderAccess: SimulatorVehicleProvider {
        simulatorProvider
    }

    init() {
        applyLoadedSettings(AppSettingsStore.load())
        settingsPersistenceEnabled = true
    }

    func setSimulatorInput(rpm: Double, throttle: Double) {
        simulatorRPM = rpm
        simulatorThrottle = throttle
        syncSimulatorProvider()
    }

    func syncSimulatorProvider() {
        simulatorProvider.setManualControlEnabled(true)
        simulatorProvider.setManualState(rpm: simulatorRPM, throttle: simulatorThrottle)
        guard isPlaying else { return }
        soundEngine.update(vehicleState: VehicleState(rpm: simulatorRPM, throttle: simulatorThrottle))
        audioDebugStatus = soundEngine.debugStatus
    }

    /// Must run synchronously on the main thread from a user gesture (Play button).
    func togglePlayback() {
        if isPlaying {
            stopSync()
        } else {
            startSync()
        }
    }

    func setDataSource(_ source: DataSource) {
        guard dataSource != source else { return }
        stopSync()
        dataSource = source
    }

    func selectProfile(_ profile: SoundProfile) {
        selectedProfile = profile
        persistSettings()
        loadSynthPatch(for: profile)
        guard audioConfigured else { return }

        let wasPlaying = isPlaying
        if wasPlaying {
            stopSync()
        }

        do {
            try soundEngine.load(profile: profile, synthPatch: profile.isSynthesized ? synthPatch : nil)
            soundEngine.setMasterVolume(masterVolume)
            audioErrorMessage = nil
            audioDebugStatus = soundEngine.debugStatus
            if wasPlaying {
                startSync()
            }
        } catch {
            audioConfigured = false
            audioErrorMessage = error.localizedDescription
            audioDebugStatus = soundEngine.debugStatus
        }
    }

    func applySynthPatch(_ patch: SynthPatch) {
        synthPatch = patch
        soundEngine.setSynthPatch(patch)
        saveSynthPatch(for: selectedProfile)
        refreshSynthDiagnostics()
        audioDebugStatus = soundEngine.debugStatus
    }

    func refreshSynthDiagnostics() {
        synthDiagnostics = soundEngine.synthDiagnostics() ?? synthDiagnostics
    }

    func resetSynthPatch() {
        applySynthPatch(SynthPatch.forProfile(selectedProfile))
        UserDefaults.standard.removeObject(forKey: synthPatchKey(for: selectedProfile.id))
    }

    private func applyLoadedSettings(_ settings: AppSettings) {
        devModeEnabled = settings.devModeEnabled
        dataSource = settings.dataSource
        simulatorRPM = settings.simulatorRPM
        simulatorThrottle = settings.simulatorThrottle

        if let profile = soundProfiles.first(where: { $0.id == settings.selectedProfileID }) {
            selectedProfile = profile
        }

        loadSynthPatch(for: selectedProfile)
        simulatorProvider.setManualState(rpm: simulatorRPM, throttle: simulatorThrottle)

        // Set master volume last without triggering engine calls before session setup.
        settingsPersistenceEnabled = false
        masterVolume = settings.masterVolume
        settingsPersistenceEnabled = true
    }

    private func persistSettings() {
        guard settingsPersistenceEnabled else { return }
        AppSettingsStore.save(AppSettings(
            selectedProfileID: selectedProfile.id,
            devModeEnabled: devModeEnabled,
            masterVolume: masterVolume,
            dataSource: dataSource,
            simulatorRPM: simulatorRPM,
            simulatorThrottle: simulatorThrottle
        ))
    }

    private func loadSynthPatch(for profile: SoundProfile) {
        guard profile.isSynthesized else { return }

        if let data = UserDefaults.standard.data(forKey: synthPatchKey(for: profile.id)),
           let saved = try? JSONDecoder().decode(SynthPatch.self, from: data) {
            synthPatch = saved
        } else {
            synthPatch = SynthPatch.forProfile(profile)
        }

        if audioConfigured {
            soundEngine.setSynthPatch(synthPatch)
        }
    }

    private func saveSynthPatch(for profile: SoundProfile) {
        guard profile.isSynthesized,
              let data = try? JSONEncoder().encode(synthPatch) else { return }
        UserDefaults.standard.set(data, forKey: synthPatchKey(for: profile.id))
    }

    private func synthPatchKey(for profileID: String) -> String {
        "synthPatch.\(profileID)"
    }

    private func startSync() {
        do {
            if !audioConfigured {
                try soundEngine.configureSession()
                loadSynthPatch(for: selectedProfile)
                try soundEngine.load(
                    profile: selectedProfile,
                    synthPatch: selectedProfile.isSynthesized ? synthPatch : nil
                )
                soundEngine.setMasterVolume(masterVolume)
                audioConfigured = true
            }

            guard soundEngine.startPlayback() else {
                audioErrorMessage = "Could not start audio playback."
                isPlaying = false
                audioDebugStatus = soundEngine.debugStatus
                return
            }

            isPlaying = true
            audioErrorMessage = nil
            audioDebugStatus = soundEngine.debugStatus

            // Telemetry can start after audio — must not block the user-gesture audio path.
            Task {
                await startProviderIfNeeded()
            }
        } catch {
            audioConfigured = false
            audioErrorMessage = error.localizedDescription
            audioDebugStatus = soundEngine.debugStatus
            isPlaying = false
        }
    }

    private func stopSync() {
        isPlaying = false
        soundEngine.stopPlayback()
        audioDebugStatus = soundEngine.debugStatus
        stateStreamTask?.cancel()
        stateStreamTask = nil
        Task {
            await activeProvider().stop()
            connectionStatus = activeProvider().connectionStatus
        }
    }

    private func activeProvider() -> any VehicleDataProvider {
        switch dataSource {
        case .simulator:
            return simulatorProvider
        case .vLinker:
            return vLinkerProvider
        }
    }

    private func startProviderIfNeeded() async {
        let provider = activeProvider()
        connectionStatus = provider.connectionStatus

        stateStreamTask?.cancel()

        stateStreamTask = Task { [weak self] in
            guard let self else { return }
            for await state in provider.stateStream {
                if Task.isCancelled { break }
                await MainActor.run {
                    self.soundEngine.update(vehicleState: state)
                    self.audioDebugStatus = self.soundEngine.debugStatus
                    self.synthDiagnostics = self.soundEngine.synthDiagnostics() ?? self.synthDiagnostics
                }
            }
        }

        await provider.start()
        connectionStatus = provider.connectionStatus
        if dataSource == .simulator {
            soundEngine.update(vehicleState: simulatorProvider.snapshotState())
        } else {
            soundEngine.update(vehicleState: .idle)
        }
        audioDebugStatus = soundEngine.debugStatus
    }
}
