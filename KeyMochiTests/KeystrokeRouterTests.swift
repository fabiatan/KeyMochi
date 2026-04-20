import Testing
@testable import KeyMochi
import CoreGraphics

@Suite("KeystrokeRouter")
struct KeystrokeRouterTests {
    @Test("passes normal keys through")
    func normalKey() {
        var out: [KeyID] = []
        let router = KeystrokeRouter(emit: { out.append($0) })
        router.ingest(KeyEvent(keyCode: 0, timestamp: 0, isRepeat: false))  // 'a'
        #expect(out == [.a])
    }

    @Test("drops auto-repeat")
    func autoRepeat() {
        var out: [KeyID] = []
        let router = KeystrokeRouter(emit: { out.append($0) })
        router.ingest(KeyEvent(keyCode: 0, timestamp: 0, isRepeat: true))
        #expect(out.isEmpty)
    }

    @Test("drops modifier-only presses")
    func modifier() {
        var out: [KeyID] = []
        let router = KeystrokeRouter(emit: { out.append($0) })
        router.ingest(KeyEvent(keyCode: 56, timestamp: 0, isRepeat: false))  // shiftLeft
        router.ingest(KeyEvent(keyCode: 55, timestamp: 0, isRepeat: false))  // commandLeft
        #expect(out.isEmpty)
    }

    @Test("drops unmapped keycodes silently")
    func unknown() {
        var out: [KeyID] = []
        let router = KeystrokeRouter(emit: { out.append($0) })
        router.ingest(KeyEvent(keyCode: 255, timestamp: 0, isRepeat: false))
        #expect(out.isEmpty)
    }
}
