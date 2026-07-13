# Active Engine Sound
## Project Plan

---

# Vision

**North Star:** vLinker connected to the truck → app reads telemetry on the iPhone → iPhone connected to truck Bluetooth → app plays engine sound driven by that telemetry through the speaker system as a background sound layer (alongside music/nav).

Create an iOS application that:

1. Connects to a **vLinker** OBD-II adapter over Bluetooth LE and reads live engine telemetry (RPM, throttle)
2. Generates engine sound that **tracks telemetry in real time**
3. Plays that sound through the **truck's speaker system** via the phone's Bluetooth/CarPlay connection, using background audio so music and other apps can still play

Inspired by Toyota's Active Sound Control on hybrid/TRD vehicles (e.g. TRD Pro).

The long-term goal is a polished application with downloadable sound packs, customizable engine profiles, and support for multiple vehicles.

The first MVP will target:

- Toyota Tundra (2022+)
- vLinker Bluetooth LE OBD-II adapter (stubbed until hardware arrives; **simulator stands in for vLinker during development**)
- iOS (SwiftUI)
- AVAudioEngine
- One bundled sound pack, no telemetry dashboard UI

---

# Goals

MVP

- Connect to simulated vehicle (stand-in for vLinker until hardware arrives)
- Generate engine sound driven by telemetry (RPM, throttle)
- Smooth RPM/throttle transitions
- Play through truck speakers as background audio (Bluetooth/CarPlay)
- Adjustable volume
- Pick from a few sounds in one bundled pack
- vLinker provider stub (real BLE/OBD deferred)

Future

- Connect to real vLinker for live truck telemetry
- Support playing as a background sound app, like navigation, so music and other apps can still play their sounds
- Multiple engine sound packs
- Turbo sounds
- Downloadable content
- Telemetry UI (optional gauges for tuning)
- CarPlay support

---

# Architecture

```
                +------------------+
                |   SwiftUI Views  |
                +---------+--------+
                          |
                ViewModels
                          |
                VehicleService
                          |
          +---------------+---------------+
          |                               |
     Simulator                  Bluetooth OBD
          |                               |
     Fake Vehicle                 vLinker BLE
          |
          +---------------+
                          |
                  VehicleState
                          |
                  Audio Engine
                          |
                  AVAudioEngine
                          |
                   Truck Speakers
```

---

# Core Modules

## VehicleDataProvider

This is the heart of the architecture.

Everything else depends on this interface.

```swift
protocol VehicleDataProvider {

    var currentState: VehicleState { get }

    func start()

    func stop()

}
```

Implementations

- SimulatorVehicleProvider
- VLinkerProvider
- PlaybackProvider (future)

The app should never know which one is active.

---

## VehicleState

```swift
struct VehicleState {

    var rpm: Double

    var throttle: Double

    var speed: Double

    var gear: Int?

    var engineLoad: Double?

}
```

---

# Simulator

The simulator is required before hardware arrives.

It should support:

Manual controls

- RPM slider
- Throttle slider
- Speed slider

Automatic driving

Idle

750 RPM

Acceleration

750 → 5500 RPM

Cruise

2200 RPM

Lift throttle

5500 → 1800 RPM

Rev limiter

Bounce around 6200 RPM

Stoplight

Idle
Accelerate
Cruise
Brake
Idle

Random drive

Automatically drives around town.

---

# Playback System

Record sessions as JSON.

Example

```json
[
    {
        "time":0.0,
        "rpm":750,
        "throttle":0
    },
    {
        "time":0.05,
        "rpm":900,
        "throttle":12
    }
]
```

This allows repeatable testing.

---

# Bluetooth Layer

Future implementation.

Responsibilities

- Scan BLE devices
- Find vLinker
- Connect
- Send OBD requests
- Parse responses
- Publish VehicleState

Supported PIDs

RPM

010C

Throttle

0111

Speed

010D

Engine Load

0104

---

# Audio Engine

Uses AVAudioEngine.

Layers

- Exhaust
- Intake
- Turbo
- Cabin resonance

Each layer is independent.

---

# Sound Profiles

```swift
struct EngineProfile {

    let name: String

    let cylinderCount: Int

    let idleRPM: Double

    let maxRPM: Double

    let harmonics: [Double]

    let turbo: Bool

}
```

Examples

Toyota TT V6

5.7 V8

Ferrari V12

GT3

Hellcat

Diesel

---

# UI

Tabs

Vehicle

Audio

Profiles

Settings

---

Vehicle Screen

Connection Status

RPM Gauge

Throttle Gauge

Speed

Gear

---

Audio Screen

Master Volume

Engine Volume

Turbo Volume

Crackle Volume

Cabin Resonance

EQ

---

Profiles

Installed sound packs

Download new profiles

Preview profile

Favorite profile

---

Settings

Bluetooth device

Auto connect

Sample rate

Debug mode

Developer mode

---

# Debug Screen

Very important.

Shows

Current provider

Packets/sec

Current PID values

Audio latency

Bluetooth latency

Frame rate

CPU usage

Dropped packets

---

# Testing

Unit Tests

Vehicle simulator

RPM smoothing

Throttle smoothing

Gear changes

JSON playback

Audio mapping

UI Tests

Simulator mode

Driving scenarios

Profile switching

---

# Milestones

## Milestone 1

Project skeleton

SwiftUI

Navigation

Architecture

Dependency Injection

Simulator

## Milestone 2

Vehicle simulator

RPM slider

Throttle slider

VehicleState publishing

## Milestone 3

Audio engine

Simple synthesized exhaust

Pitch follows RPM

Volume follows throttle

## Milestone 4

Multi-layer audio

Turbo

Intake

Cabin

Crackles

## Milestone 5

Bluetooth

BLE discovery

Connect to vLinker

Read RPM

Read throttle

Read speed

## Milestone 6

Real vehicle testing

Latency improvements

Signal smoothing

Reconnect logic

## Milestone 7

Sound packs

Import/export

Custom profiles

Profile editor

---

# Stretch Goals

- CarPlay interface
- AI-generated sound profiles
- Recording actual engine audio to create custom profiles

---

# Development Philosophy

Everything in the app should work without owning a vehicle.

If Bluetooth hardware is unavailable, switch to the simulator.

Every feature should be testable using simulated VehicleState objects.

Vehicle data should be considered an interchangeable source.

The audio engine should never know whether data came from:

- Simulator
- Real OBD-II
- Recorded session

Only VehicleState.