import Foundation
import AVFoundation
import os.lock

/// Picks a sample variant for each keypress and dispatches to the audio layer.
/// Called synchronously from the CGEventTap callback via `handleSync`.
/// Dependency-injects the audio fire callback for testability.
final class SoundPackEngine: @unchecked Sendable {
    typealias AudioFire = (AVAudioPCMBuffer, AVAudio3DPoint, Float) -> Void

    /// Per-key rate multiplier. The spacebar sample in most Mechvibes packs is
    /// recorded from the largest resonant key body and sounds disproportionately
    /// deep next to the normal alphas — pitching it up ~2 semitones keeps its
    /// distinctive thock while rebalancing it against the rest of the pack.
    private static let rateBiasByKey: [KeyID: Float] = [
        .space: 1.122  // 2^(2/12) ≈ +2 semitones
    ]

    private let audioFire: AudioFire
    private let layout: SpatialLayout

    // Immutable per active pack; swap atomically when user picks a new pack.
    private let state: OSAllocatedUnfairLock<State>

    private struct State {
        var pack: SoundPack?
        /// For each key, the index of the last-played variant. Used to guarantee
        /// no immediate repeat.
        var lastVariantIndex: [KeyID: Int] = [:]
    }

    init(audioFire: @escaping AudioFire, layout: SpatialLayout) {
        self.audioFire = audioFire
        self.layout = layout
        self.state = .init(initialState: State())
    }

    func setPack(_ pack: SoundPack) {
        state.withLock { $0 = State(pack: pack, lastVariantIndex: [:]) }
    }

    /// Hot-path entry. Safe to call from CGEventTap callback thread.
    func handleSync(keyID: KeyID) {
        guard let position = layout.position(for: keyID) else { return }
        let maybeBuffer: AVAudioPCMBuffer? = state.withLock { s in
            guard let pack = s.pack,
                  let set = pack.press[keyID],
                  !set.variants.isEmpty else { return nil }
            let idx = Self.nextIndex(
                variantCount: set.variants.count,
                last: s.lastVariantIndex[keyID]
            )
            s.lastVariantIndex[keyID] = idx
            return set.variants[idx]
        }
        guard let buffer = maybeBuffer else { return }
        let rateBias = Self.rateBiasByKey[keyID] ?? 1.0
        audioFire(buffer, position, rateBias)
    }

    /// Picks a variant index different from the last one (when possible).
    private static func nextIndex(variantCount n: Int, last: Int?) -> Int {
        if n == 1 { return 0 }
        let pick = Int.random(in: 0..<n)
        if let last, pick == last {
            return (pick + 1) % n
        }
        return pick
    }
}
