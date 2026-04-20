import Foundation
import os.lock

/// A fixed-size ring of voice indices. `acquire()` returns the next index
/// (wrapping), implementing oldest-first voice stealing. Thread-safe via
/// `OSAllocatedUnfairLock` — near-lock-free under no contention (~20 ns),
/// blocking under contention (rare: hot path is single-threaded from
/// CGEventTap callback).
final class VoicePool: @unchecked Sendable {
    let capacity: Int
    private let head: OSAllocatedUnfairLock<Int> = .init(initialState: 0)

    init(capacity: Int) {
        precondition(capacity > 0, "VoicePool capacity must be positive")
        self.capacity = capacity
    }

    /// Return the next voice index, advancing the ring.
    func acquire() -> Int {
        head.withLock { h in
            let current = h
            h = (h + 1) % capacity
            return current
        }
    }
}
