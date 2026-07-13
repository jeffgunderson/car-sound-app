# Active Engine Sound

iOS app that plays telemetry-driven engine sounds through your car's speaker system (phone → Bluetooth/CarPlay), inspired by Toyota's Active Sound Control on hybrid/TRD vehicles.

## MVP Features

- **One sound pack** (Tundra TRD) with 3 selectable profiles
- **Telemetry-driven audio** — pitch follows RPM, volume follows throttle
- **Offline simulator** — test without a vLinker OBD adapter
- **vLinker stub** — architecture ready for real BLE/OBD when hardware arrives

## Requirements

- Xcode 15+ (iOS 17+ deployment target)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (optional — project is committed, regenerate with `xcodegen generate`)

## Getting Started

1. Open `CarSoundApp.xcodeproj` in Xcode
2. Select an iPhone simulator or device
3. Build and run (⌘R)

### Regenerating the Xcode project

If you change `project.yml`:

```bash
xcodegen generate
```

### Regenerating placeholder sound samples

Bundled WAV files are procedural placeholders for development. Replace them with real engine recordings when available.

```bash
python3 scripts/generate_sounds.py
```

## Using the App

### Main screen

- Pick a sound profile from the Tundra TRD pack
- Adjust master volume
- Tap **Play** to start engine sound through the device speakers (or car Bluetooth)

### Offline testing (Dev Mode)

1. Open **Settings** → enable **Dev Mode**
2. Return to the main screen — simulator controls appear
3. Use RPM/throttle sliders or preset scenarios:
   - **Idle** — 750 RPM
   - **Acceleration** — 750 → 5500 RPM
   - **Cruise** — 2200 RPM
   - **Rev Limiter** — bounce at ~6200 RPM
   - **Stoplight Cycle** — idle → accel → cruise → brake → idle

Audio responds in real time as simulated vehicle state changes.

### Data sources

| Source | Status | Description |
|--------|--------|-------------|
| Simulator | Working | Default — mimics OBD telemetry for offline development |
| vLinker | Stub | Placeholder until BLE/OBD implementation |

Switch data source in **Settings → Data Source**.

## Architecture

```
SwiftUI Views → AppViewModel → VehicleDataProvider
                                    ├── SimulatorVehicleProvider (MVP)
                                    └── VLinkerProvider (stub)
                              VehicleState → SoundEngine → AVAudioSession → Car speakers
```

Audio never knows whether data comes from the simulator or vLinker — only `VehicleState` (RPM + throttle).

## vLinker Roadmap

When your vLinker MC+ module arrives:

1. Implement BLE discovery and connection in `VLinkerProvider`
2. Poll OBD-II PIDs:
   - `010C` — Engine RPM
   - `0111` — Throttle position
3. Publish `VehicleState` on the existing `stateStream`
4. Switch **Settings → Data Source → vLinker**

No changes needed to `SoundEngine` or the main UI.

## Project Structure

```
CarSoundApp/
├── App/              App entry point
├── Models/           VehicleState, SoundProfile, ConnectionStatus
├── Providers/        VehicleDataProvider + implementations
├── Audio/            SoundEngine (AVAudioEngine)
├── ViewModels/       AppViewModel
├── Views/            MainView, SettingsView, DevSimulatorView
└── Resources/Sounds/ Bundled WAV samples
```

## In-Car Testing

Connect your iPhone to the truck via Bluetooth before tapping Play. The app uses `AVAudioSession` with `.mixWithOthers` so engine sound can play alongside music/navigation, similar to how nav prompts work.

## License

Private project.
