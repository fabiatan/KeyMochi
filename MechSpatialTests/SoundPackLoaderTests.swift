import Testing
import Foundation
import AVFoundation
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

@Suite("SoundPackLoader — full pack load")
struct SoundPackLoaderFullTests {
    private var fixtureURL: URL {
        Bundle(for: FixtureLocator.self)
            .url(forResource: "test-pack", withExtension: nil,
                 subdirectory: "Fixtures")!
    }

    @Test("loads a pack end-to-end with decoded buffers")
    func loadsPack() throws {
        let pack = try SoundPackLoader.load(from: fixtureURL)
        #expect(pack.id == "test-pack")
        #expect(pack.character == .clacky)
        #expect(pack.layoutID == "qwerty_us")

        let aSet = try #require(pack.press[.a])
        #expect(aSet.variants.count == 1)
        #expect(aSet.variants[0].frameLength > 0)

        let sSet = try #require(pack.press[.s])
        #expect(sSet.variants.count == 1)
    }

    @Test("throws on missing sample file")
    func missingSample() throws {
        let tempDir = try makeTempPackWithBadSample()
        #expect(throws: PackError.self) {
            try SoundPackLoader.load(from: tempDir)
        }
    }

    private func makeTempPackWithBadSample() throws -> URL {
        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent(
            "bad-pack-\(UUID().uuidString)")
        try fm.createDirectory(at: temp, withIntermediateDirectories: true)
        let config = """
        {"id":"bad","name":"Bad","author":"x","character":"clacky",
         "version":"1.0.0","sound_format":"wav","key_define_type":"single",
         "defines":{"0":["press/does-not-exist.wav"]}}
        """
        try config.write(to: temp.appendingPathComponent("config.json"),
                         atomically: true, encoding: .utf8)
        return temp
    }
}
