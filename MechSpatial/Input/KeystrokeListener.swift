import Foundation
import CoreGraphics
import AppKit
import os.lock

/// Installs a system-wide CGEventTap for key-down events. The `onKeyDownSync`
/// closure is called synchronously on the event-tap thread — it must not
/// allocate, block, or log.
final class KeystrokeListener: @unchecked Sendable {
    /// Hot path. Called on event-tap thread. Do not allocate, log, or block.
    var onKeyDownSync: (@Sendable (CGKeyCode, CFTimeInterval, Bool) -> Void)?

    /// Non-hot-path channel. Consumed by stats/UI on the main actor.
    let eventStream: AsyncStream<KeyEvent>
    private let continuation: AsyncStream<KeyEvent>.Continuation

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapEnabledLock = OSAllocatedUnfairLock<Bool>(initialState: false)

    init() {
        var cont: AsyncStream<KeyEvent>.Continuation!
        self.eventStream = AsyncStream(bufferingPolicy: .bufferingNewest(256)) { c in
            cont = c
        }
        self.continuation = cont
    }

    func start() throws {
        let mask = (1 << CGEventType.keyDown.rawValue)
        let unmanagedSelf = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: { proxy, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let listener = Unmanaged<KeystrokeListener>
                    .fromOpaque(userInfo).takeUnretainedValue()
                listener.handle(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: unmanagedSelf
        ) else {
            throw ListenerError.tapCreationFailed
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.eventTap = tap
        self.runLoopSource = source
        tapEnabledLock.withLock { $0 = true }
    }

    func stop() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        tapEnabledLock.withLock { $0 = false }
    }

    /// Hot path — event-tap thread.
    private func handle(type: CGEventType, event: CGEvent) {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return
        case .keyDown:
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            let ts = CFAbsoluteTimeGetCurrent()
            onKeyDownSync?(keyCode, ts, isRepeat)
            continuation.yield(KeyEvent(
                keyCode: keyCode, timestamp: ts, isRepeat: isRepeat))
        default:
            return
        }
    }

    enum ListenerError: Error {
        case tapCreationFailed
    }
}
