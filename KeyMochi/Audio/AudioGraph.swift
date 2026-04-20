import Foundation
import AVFoundation
import CoreAudio
import os.signpost

private let graphSignposter = OSSignposter(subsystem: "com.fabian.keymochi", category: "audio")

/// Wraps AVAudioEngine + an AVAudioEnvironmentNode (HRTF) + a fixed pool
/// of AVAudioPlayerNodes. Use `fireSync(buffer:at:)` on the hot path.
final class AudioGraph: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private let environment = AVAudioEnvironmentNode()
    private let voicePool: VoicePool
    private var players: [AVAudioPlayerNode] = []
    private let mixer = AVAudioMixerNode()

    /// Listener at origin by default, facing -Z.
    private(set) var listenerPosition: AVAudio3DPoint = .init(x: 0, y: 0, z: 0)

    init(voiceCount: Int = 16) {
        self.voicePool = VoicePool(capacity: voiceCount)
    }

    func prepare() throws {
        environment.renderingAlgorithm = .HRTFHQ
        environment.listenerPosition = listenerPosition
        environment.listenerVectorOrientation = AVAudio3DVectorOrientation(
            forward: .init(x: 0, y: 0, z: -1),
            up: .init(x: 0, y: 1, z: 0)
        )
        environment.outputVolume = 1.0

        engine.attach(environment)
        engine.attach(mixer)
        for _ in 0..<voicePool.capacity {
            let p = AVAudioPlayerNode()
            engine.attach(p)
            players.append(p)
        }

        // Graph: players (MONO) -> environment (HRTF -> STEREO) -> mixer -> output
        // The environment node *requires* mono input for HRTF to apply;
        // stereo input is passed through unspatialized.
        let monoFormat = SoundPackLoader.standardFormat   // 48 kHz mono float32
        let stereoFormat = AVAudioFormat(
            standardFormatWithSampleRate: 48_000, channels: 2)!

        for player in players {
            engine.connect(player, to: environment, format: monoFormat)
        }
        engine.connect(environment, to: mixer, format: stereoFormat)
        engine.connect(mixer, to: engine.outputNode, format: stereoFormat)

        mixer.outputVolume = 1.0

        // Lower CoreAudio I/O buffer to ~2.7 ms (128 frames @ 48 kHz) for
        // minimum render latency. Best-effort — the OS may clamp to its allowed
        // range. Failure is non-fatal.
        try? setOutputBufferFrameSize(128)

        engine.prepare()
        try engine.start()

        // Pre-warm: play one silent buffer through each voice so CoreAudio
        // finishes JIT setup for every node.
        let silent = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: 128)!
        silent.frameLength = 128
        for player in players {
            player.play()
            player.scheduleBuffer(silent, at: nil, options: [], completionHandler: nil)
        }
    }

    /// Best-effort lower the CoreAudio output buffer size on the default device.
    private func setOutputBufferFrameSize(_ frames: UInt32) throws {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        let getStatus = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &addr, 0, nil, &size, &deviceID)
        guard getStatus == noErr else { return }

        var bufferSize = frames
        var bufAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyBufferFrameSize,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        _ = AudioObjectSetPropertyData(
            deviceID, &bufAddr, 0, nil,
            UInt32(MemoryLayout<UInt32>.size), &bufferSize)
        // No error propagation — clamping by OS is normal and harmless.
    }

    func stop() {
        for player in players { player.stop() }
        engine.stop()
    }

    /// Hot-path fire. Picks a voice, schedules the buffer at the given position.
    /// Must be safe to call from the CGEventTap thread.
    func fireSync(buffer: AVAudioPCMBuffer, at position: AVAudio3DPoint) {
        let state = graphSignposter.beginInterval("fireSync", id: graphSignposter.makeSignpostID())
        defer { graphSignposter.endInterval("fireSync", state) }
        let idx = voicePool.acquire()
        let player = players[idx]
        player.position = position
        player.renderingAlgorithm = .HRTFHQ
        if !player.isPlaying { player.play() }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts,
                              completionHandler: nil)
    }

    func setListenerPosition(_ pos: AVAudio3DPoint) {
        listenerPosition = pos
        environment.listenerPosition = pos
    }

    func setMasterVolume(_ v: Float) {
        mixer.outputVolume = max(0, min(1, v))
    }

    /// For smoke testing: fire a one-off noise burst at a given position.
    func smokeTest(at position: AVAudio3DPoint) {
        let format = SoundPackLoader.standardFormat  // mono 48 kHz float32
        let frameCount = AVAudioFrameCount(format.sampleRate * 0.05)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let amplitude: Float = 0.1
        let ptr = buffer.floatChannelData![0]
        for frame in 0..<Int(frameCount) {
            ptr[frame] = Float.random(in: -amplitude...amplitude)
        }
        fireSync(buffer: buffer, at: position)
    }
}
