import Foundation
import CoreGraphics

struct KeyEvent: Sendable, Equatable {
    let keyCode: CGKeyCode
    let timestamp: CFTimeInterval
    let isRepeat: Bool
}

/// Filters raw KeyEvents and emits `KeyID`s suitable for audio.
/// Stateless today; a future v1.x may add a "silent mode during secure input"
/// or app-specific filtering.
final class KeystrokeRouter: @unchecked Sendable {
    private let emit: @Sendable (KeyID) -> Void

    init(emit: @escaping @Sendable (KeyID) -> Void) {
        self.emit = emit
    }

    /// Hot-path entry. Called from the event-tap thread.
    func ingest(_ event: KeyEvent) {
        if event.isRepeat { return }
        guard let keyID = KeyID(keyCode: event.keyCode) else { return }
        if keyID.isModifier { return }
        emit(keyID)
    }
}
