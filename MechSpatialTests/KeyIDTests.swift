import Testing
@testable import MechSpatial

@Suite("KeyID mapping")
struct KeyIDTests {
    @Test("maps common alphabetic keys")
    func alphabeticKeys() {
        #expect(KeyID(keyCode: 0) == .a)
        #expect(KeyID(keyCode: 1) == .s)
        #expect(KeyID(keyCode: 2) == .d)
        #expect(KeyID(keyCode: 12) == .q)
        #expect(KeyID(keyCode: 14) == .e)
        #expect(KeyID(keyCode: 16) == .y)
    }

    @Test("maps number row")
    func numberRow() {
        #expect(KeyID(keyCode: 18) == .one)
        #expect(KeyID(keyCode: 19) == .two)
        #expect(KeyID(keyCode: 29) == .zero)
    }

    @Test("maps space and modifiers")
    func specialKeys() {
        #expect(KeyID(keyCode: 49) == .space)
        #expect(KeyID(keyCode: 36) == .returnKey)
        #expect(KeyID(keyCode: 51) == .delete)
        #expect(KeyID(keyCode: 53) == .escape)
    }

    @Test("unknown keycodes return nil")
    func unknownKeycode() {
        #expect(KeyID(keyCode: 255) == nil)
    }

    @Test("every KeyID has a rawValue")
    func everyIDHasRawValue() {
        for id in KeyID.allCases {
            #expect(!id.rawValue.isEmpty)
        }
    }
}
