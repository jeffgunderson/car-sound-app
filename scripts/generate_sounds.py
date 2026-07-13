#!/usr/bin/env python3
"""Generate placeholder engine loop WAV files for the Tundra TRD sound pack."""

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
DURATION_SECONDS = 4.0
OUTPUT_DIR = Path(__file__).resolve().parent.parent / "CarSoundApp" / "Resources" / "Sounds" / "TundraTRD"

# Three loops per profile — crossfaded by RPM in the app (minimal pitch shift).
PROFILES = {
    "trd_v6_balanced": {
        "idle": {"base_freq": 42.0, "harmonics": [1.0, 0.45, 0.22, 0.10], "noise": 0.025, "pulse": 0.07},
        "cruise": {"base_freq": 52.0, "harmonics": [1.0, 0.55, 0.30, 0.15], "noise": 0.035, "pulse": 0.08},
        "high": {"base_freq": 66.0, "harmonics": [1.0, 0.60, 0.35, 0.18], "noise": 0.045, "pulse": 0.09},
    },
    "trd_v6_aggressive": {
        "idle": {"base_freq": 46.0, "harmonics": [1.0, 0.50, 0.25, 0.12], "noise": 0.030, "pulse": 0.08},
        "cruise": {"base_freq": 58.0, "harmonics": [1.0, 0.65, 0.38, 0.18], "noise": 0.040, "pulse": 0.09},
        "high": {"base_freq": 72.0, "harmonics": [1.0, 0.72, 0.42, 0.22], "noise": 0.055, "pulse": 0.10},
    },
    "trd_v8_deep": {
        "idle": {"base_freq": 32.0, "harmonics": [1.0, 0.55, 0.28, 0.14], "noise": 0.028, "pulse": 0.06},
        "cruise": {"base_freq": 40.0, "harmonics": [1.0, 0.62, 0.34, 0.16], "noise": 0.038, "pulse": 0.07},
        "high": {"base_freq": 50.0, "harmonics": [1.0, 0.68, 0.38, 0.20], "noise": 0.048, "pulse": 0.08},
    },
}


def generate_sample(output_path: Path, config: dict) -> None:
    total_samples = int(SAMPLE_RATE * DURATION_SECONDS)
    samples = []

    for i in range(total_samples):
        t = i / SAMPLE_RATE
        value = 0.0

        for harmonic_index, amplitude in enumerate(config["harmonics"], start=1):
            freq = config["base_freq"] * harmonic_index
            value += amplitude * math.sin(2.0 * math.pi * freq * t)

        pulse = 1.0 + config["pulse"] * math.sin(2.0 * math.pi * (config["base_freq"] / 2.0) * t)
        value *= pulse

        noise = config["noise"] * math.sin(2.0 * math.pi * 173.0 * t + math.sin(t * 9.0))
        value += noise

        value = max(min(value * 0.18, 0.95), -0.95)
        samples.append(int(value * 32767))

    output_path.parent.mkdir(parents=True, exist_ok=True)

    with wave.open(str(output_path), "w") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        frames = b"".join(struct.pack("<h", sample) for sample in samples)
        wav_file.writeframes(frames)


def main() -> None:
    # Remove legacy single-loop files.
    for legacy_name in (
        "trd_v6_balanced.wav",
        "trd_v6_aggressive.wav",
        "trd_v8_deep.wav",
    ):
        legacy = OUTPUT_DIR / legacy_name
        if legacy.exists():
            legacy.unlink()
            print(f"Removed legacy {legacy}")

    for profile_prefix, tiers in PROFILES.items():
        for tier_name, tier_config in tiers.items():
            output_path = OUTPUT_DIR / f"{profile_prefix}_{tier_name}.wav"
            generate_sample(output_path, tier_config)
            print(f"Wrote {output_path}")


if __name__ == "__main__":
    main()
