# KeyMochi

Native macOS app that plays spatialised mechanical-keyboard sounds in response to your keystrokes — like the keyboard is sitting on the desk in front of you, not inside your laptop's speaker.

## How it works

1. `CGEventTap` on a background thread observes key events system-wide (requires Accessibility permission).
2. `KeystrokeRouter` filters out modifiers and auto-repeats.
3. `SoundPackEngine` looks up the per-key WAV buffer for the active pack.
4. `AudioGraph` plays it through an `AVAudioEnvironmentNode` with HRTF spatialisation, positioned using the current QWERTY layout and the listener's virtual head position.

All hot-path types are `final class @unchecked Sendable` with internally-locked state so the event tap thread can fire synchronously without hopping queues.

## Build & run

Open `KeyMochi.xcodeproj` in Xcode 16+ on macOS 14+ and run the `KeyMochi` scheme. On first launch you'll be prompted to grant Accessibility permission in System Settings → Privacy & Security.

## Latency budget

| Interval | Target | Source |
|---|---|---|
| `key→fire` (event tap → `fireSync` return) | < 500 µs | `OSSignposter(subsystem: "com.fabian.keymochi", category: "hotpath")` |
| `fireSync` (voice allocation + buffer schedule) | < 250 µs | `OSSignposter(subsystem: "com.fabian.keymochi", category: "audio")` |
| End-to-end (key press → speaker) | ~10 ms wired, ~50–250 ms Bluetooth | Wired/BT difference shown in-app |

### Measured latency

Run Instruments → **os_signpost** template against a Release build and record:

| Interval | p50 | p95 | Notes |
|---|---|---|---|
| `key→fire` | _TBD_ | _TBD_ | |
| `fireSync` | _TBD_ | _TBD_ | |

Fill this in after the first measurement pass.

## Docs

- [`KeyMochi/docs/smoke-tests.md`](KeyMochi/docs/smoke-tests.md) — manual QA checklist
