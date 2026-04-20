import CoreGraphics

/// Canonical identifier for a physical key on a US-QWERTY Mac keyboard.
/// Distinct from the character a key produces — we care about the physical
/// location (for spatial audio) and the physical switch (for sound).
enum KeyID: String, CaseIterable, Sendable {
    // Letters
    case a, b, c, d, e, f, g, h, i, j, k, l, m
    case n, o, p, q, r, s, t, u, v, w, x, y, z
    // Number row
    case one, two, three, four, five, six, seven, eight, nine, zero
    // Punctuation
    case grave, minus, equal, leftBracket, rightBracket, backslash
    case semicolon, quote, comma, period, slash
    // Navigation
    case returnKey, tab, space, delete, escape, forwardDelete
    case leftArrow, rightArrow, upArrow, downArrow
    case home, end, pageUp, pageDown
    // Modifiers (recorded here but filtered out before audio)
    case shiftLeft, shiftRight, controlLeft, controlRight
    case optionLeft, optionRight, commandLeft, commandRight
    case capsLock, function
    // Function row
    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12

    init?(keyCode: CGKeyCode) {
        guard let id = Self.byKeyCode[keyCode] else { return nil }
        self = id
    }

    var isModifier: Bool {
        switch self {
        case .shiftLeft, .shiftRight, .controlLeft, .controlRight,
             .optionLeft, .optionRight, .commandLeft, .commandRight,
             .capsLock, .function:
            return true
        default:
            return false
        }
    }

    /// Canonical CGKeyCode → KeyID map.
    /// Reference: `HIToolbox/Events.h` kVK_* constants.
    static let byKeyCode: [CGKeyCode: KeyID] = [
        // Letters (alphabetic order of keyCode, not letter)
        0: .a, 1: .s, 2: .d, 3: .f, 4: .h, 5: .g, 6: .z, 7: .x,
        8: .c, 9: .v, 11: .b, 12: .q, 13: .w, 14: .e, 15: .r,
        16: .y, 17: .t, 31: .o, 32: .u, 34: .i, 35: .p, 37: .l,
        38: .j, 40: .k, 45: .n, 46: .m,
        // Number row
        18: .one, 19: .two, 20: .three, 21: .four, 23: .five,
        22: .six, 26: .seven, 28: .eight, 25: .nine, 29: .zero,
        // Punctuation
        50: .grave, 27: .minus, 24: .equal,
        33: .leftBracket, 30: .rightBracket, 42: .backslash,
        41: .semicolon, 39: .quote, 43: .comma, 47: .period, 44: .slash,
        // Navigation
        36: .returnKey, 48: .tab, 49: .space, 51: .delete,
        53: .escape, 117: .forwardDelete,
        123: .leftArrow, 124: .rightArrow, 126: .upArrow, 125: .downArrow,
        115: .home, 119: .end, 116: .pageUp, 121: .pageDown,
        // Modifiers
        56: .shiftLeft, 60: .shiftRight,
        59: .controlLeft, 62: .controlRight,
        58: .optionLeft, 61: .optionRight,
        55: .commandLeft, 54: .commandRight,
        57: .capsLock, 63: .function,
        // Function row
        122: .f1, 120: .f2, 99: .f3, 118: .f4, 96: .f5, 97: .f6,
        98: .f7, 100: .f8, 101: .f9, 109: .f10, 103: .f11, 111: .f12,
    ]
}
