import Testing
import Foundation
@testable import MechSpatial

@Suite("SoundPackLoader — config parsing")
struct SoundPackLoaderConfigTests {
    private var fixtureURL: URL {
        Bundle(for: FixtureLocator.self)
            .url(forResource: "test-pack", withExtension: nil,
                 subdirectory: "Fixtures")!
    }

    @Test("parses valid config.json")
    func parsesValidConfig() throws {
        let config = try SoundPackLoader.parseConfig(at: fixtureURL)
        #expect(config.id == "test-pack")
        #expect(config.name == "Test Pack")
        #expect(config.character == .clacky)
        #expect(config.defines["0"] == ["press/a.wav"])
        #expect(config.spatial_layout == "qwerty_us")
    }

    @Test("rejects missing config.json")
    func rejectsMissingConfig() {
        let bogus = fixtureURL.appendingPathComponent("no-such-dir")
        #expect(throws: PackError.self) {
            try SoundPackLoader.parseConfig(at: bogus)
        }
    }
}

/// Marker class used to locate the test bundle.
final class FixtureLocator {}
