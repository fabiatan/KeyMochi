import Foundation
import AVFoundation
import CoreGraphics

enum SoundPackLoader {
    static func parseConfig(at packDirectory: URL) throws -> SoundPackConfig {
        let configURL = packDirectory.appendingPathComponent("config.json")
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            throw PackError.invalidConfig("config.json not found at \(configURL.path)")
        }
        do {
            let data = try Data(contentsOf: configURL)
            return try JSONDecoder().decode(SoundPackConfig.self, from: data)
        } catch {
            throw PackError.invalidConfig(String(describing: error))
        }
    }

    /// Load a pack: parse config and decode all WAV samples into PCM buffers.
    static func load(from packDirectory: URL) throws -> SoundPack {
        let config = try parseConfig(at: packDirectory)
        let press = try decodeKeyMap(config.defines, relativeTo: packDirectory)
        let release = try decodeKeyMap(config.release_defines ?? [:],
                                       relativeTo: packDirectory)
        return SoundPack(
            id: config.id,
            name: config.name,
            author: config.author,
            character: config.character,
            version: config.version,
            layoutID: config.spatial_layout ?? "qwerty_us",
            press: press,
            release: release
        )
    }

    private static func decodeKeyMap(
        _ raw: [String: [String]],
        relativeTo packDir: URL
    ) throws -> [KeyID: SampleSet] {
        var result: [KeyID: SampleSet] = [:]
        for (keyCodeStr, samplePaths) in raw {
            guard let keyCodeInt = UInt16(keyCodeStr),
                  let keyID = KeyID(keyCode: CGKeyCode(keyCodeInt)) else {
                continue  // unknown keycode — skip silently (future-proofing)
            }
            var variants: [AVAudioPCMBuffer] = []
            for relPath in samplePaths {
                let url = packDir.appendingPathComponent(relPath)
                guard FileManager.default.fileExists(atPath: url.path) else {
                    throw PackError.missingSample(relPath)
                }
                variants.append(try decodeWAV(at: url))
            }
            if !variants.isEmpty {
                result[keyID] = SampleSet(variants: variants)
            }
        }
        return result
    }

    /// Standard processing format used app-wide. MONO is required by
    /// AVAudioEnvironmentNode for HRTF spatialization to work — stereo input
    /// would be passed through without 3D positioning. The environment node
    /// produces stereo output via HRTF after spatializing each mono source.
    static let standardFormat: AVAudioFormat = AVAudioFormat(
        standardFormatWithSampleRate: 48_000, channels: 1)!

    /// Decode a WAV file and convert to `standardFormat` (48 kHz mono float32).
    /// Stereo source files are downmixed; sample-rate differences are converted.
    private static func decodeWAV(at url: URL) throws -> AVAudioPCMBuffer {
        let file: AVAudioFile
        do {
            file = try AVAudioFile(forReading: url)
        } catch {
            throw PackError.decodingFailed(url.lastPathComponent)
        }
        guard let sourceBuffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(file.length)
        ) else {
            throw PackError.decodingFailed(url.lastPathComponent)
        }
        do {
            try file.read(into: sourceBuffer)
        } catch {
            throw PackError.decodingFailed(url.lastPathComponent)
        }

        // Fast path: source already matches.
        if file.processingFormat.sampleRate == standardFormat.sampleRate
            && file.processingFormat.channelCount == standardFormat.channelCount {
            return sourceBuffer
        }

        // Convert to standardFormat.
        guard let converter = AVAudioConverter(
            from: file.processingFormat, to: standardFormat) else {
            throw PackError.decodingFailed("converter init: \(url.lastPathComponent)")
        }
        let ratio = standardFormat.sampleRate / file.processingFormat.sampleRate
        let outCapacity = AVAudioFrameCount(Double(sourceBuffer.frameLength) * ratio + 32)
        guard let outBuffer = AVAudioPCMBuffer(
            pcmFormat: standardFormat, frameCapacity: outCapacity) else {
            throw PackError.decodingFailed("output buffer alloc: \(url.lastPathComponent)")
        }
        var consumed = false
        var convError: NSError?
        let status = converter.convert(to: outBuffer, error: &convError) { _, outStatus in
            if consumed {
                outStatus.pointee = .endOfStream
                return nil
            }
            consumed = true
            outStatus.pointee = .haveData
            return sourceBuffer
        }
        if status == .error || convError != nil {
            throw PackError.decodingFailed("conversion: \(url.lastPathComponent)")
        }
        return outBuffer
    }
}
