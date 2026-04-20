import Foundation
import AVFoundation
import os.lock

/// Thin wrapper around loaded packs, keyed by pack id. Owns the strong refs
/// to PCM buffers so they stay resident for the engine's lifetime.
/// Currently a simple dictionary; placeholder for LRU eviction if we ever
/// support dynamic pack unloading.
final class AudioSampleCache: @unchecked Sendable {
    private var packs: [String: SoundPack] = [:]
    private let lock = OSAllocatedUnfairLock<Void>(initialState: ())

    func put(_ pack: SoundPack) {
        lock.withLockUnchecked { packs[pack.id] = pack }
    }

    func get(_ id: String) -> SoundPack? {
        lock.withLockUnchecked { packs[id] }
    }

    var all: [SoundPack] {
        lock.withLockUnchecked { Array(packs.values) }
    }
}
