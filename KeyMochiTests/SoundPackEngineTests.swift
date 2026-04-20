import Testing
import AVFoundation
@testable import KeyMochi

@Suite("SoundPackEngine — round-robin")
struct SoundPackEngineTests {
    /// Creates a pack with N fake variants for key `.a`.
    private func fakePack(variants: Int) -> SoundPack {
        let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)!
        let bufs: [AVAudioPCMBuffer] = (0..<variants).map { _ in
            let b = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 128)!
            b.frameLength = 128
            return b
        }
        return SoundPack(
            id: "fake", name: "Fake", author: "", character: "clacky",
            version: "1", layoutID: "qwerty_us",
            press: [.a: SampleSet(variants: bufs)],
            release: [:]
        )
    }

    @Test("never picks the same variant twice in a row")
    func noImmediateRepeat() throws {
        let pack = fakePack(variants: 3)
        let layout = try SpatialLayout.load(id: "qwerty_us")
        let recorder = FireRecorder()
        let engine = SoundPackEngine(
            audioFire: recorder.fire,
            layout: layout
        )
        engine.setPack(pack)
        for _ in 0..<100 { engine.handleSync(keyID: .a) }
        #expect(recorder.fires.count == 100)
        for i in 1..<recorder.fires.count {
            #expect(recorder.fires[i].buffer !== recorder.fires[i-1].buffer)
        }
    }

    @Test("single-variant pack always fires the same buffer (no crash)")
    func singleVariant() throws {
        let pack = fakePack(variants: 1)
        let layout = try SpatialLayout.load(id: "qwerty_us")
        let recorder = FireRecorder()
        let engine = SoundPackEngine(
            audioFire: recorder.fire,
            layout: layout
        )
        engine.setPack(pack)
        for _ in 0..<5 { engine.handleSync(keyID: .a) }
        #expect(recorder.fires.count == 5)
    }

    @Test("unmapped key is silently ignored")
    func unmappedKey() throws {
        let pack = fakePack(variants: 2)  // only maps .a
        let layout = try SpatialLayout.load(id: "qwerty_us")
        let recorder = FireRecorder()
        let engine = SoundPackEngine(
            audioFire: recorder.fire,
            layout: layout
        )
        engine.setPack(pack)
        engine.handleSync(keyID: .z)  // not in pack
        #expect(recorder.fires.isEmpty)
    }
}

/// Test double that captures fires for inspection.
final class FireRecorder: @unchecked Sendable {
    struct Fire {
        let buffer: AVAudioPCMBuffer
        let position: AVAudio3DPoint
        let rateBias: Float
    }
    private(set) var fires: [Fire] = []
    func fire(buffer: AVAudioPCMBuffer, position: AVAudio3DPoint, rateBias: Float) {
        fires.append(Fire(buffer: buffer, position: position, rateBias: rateBias))
    }
}
