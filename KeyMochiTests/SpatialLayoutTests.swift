import Testing
import AVFoundation
@testable import KeyMochi

@Suite("SpatialLayout")
struct SpatialLayoutTests {
    @Test("loads qwerty_us layout from bundle")
    func loadsQwertyUS() throws {
        let layout = try SpatialLayout.load(id: "qwerty_us")
        #expect(layout.id == "qwerty_us")
        #expect(layout.position(for: .space) != nil)
        #expect(layout.position(for: .a) != nil)
        #expect(layout.position(for: .p) != nil)
    }

    @Test("A is left of P on qwerty_us")
    func spatialOrdering() throws {
        let layout = try SpatialLayout.load(id: "qwerty_us")
        let a = try #require(layout.position(for: .a))
        let p = try #require(layout.position(for: .p))
        #expect(a.x < p.x)
    }

    @Test("missing layout throws")
    func missingLayout() {
        #expect(throws: Error.self) {
            try SpatialLayout.load(id: "does-not-exist")
        }
    }
}
