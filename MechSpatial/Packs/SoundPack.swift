import Foundation
import AVFoundation

/// Character category for a sound pack — one of the five reference profiles.
enum SoundCharacter: String, Codable, Sendable, CaseIterable {
    case creamy, thocky, clacky, poppy, clicky
}

/// Round-robin variant set for a single key action (press or release).
struct SampleSet: Sendable {
    /// Variant buffers (pre-decoded PCM). Non-empty.
    var variants: [AVAudioPCMBuffer]
}

/// A loaded sound pack. `press` and optional `release` maps KeyID → variants.
struct SoundPack: Sendable, Identifiable {
    let id: String
    let name: String
    let author: String
    let character: SoundCharacter
    let version: String
    let layoutID: String
    let press: [KeyID: SampleSet]
    let release: [KeyID: SampleSet]
}

/// Parsed (but not yet sample-decoded) config.json — used internally by the loader.
struct SoundPackConfig: Decodable {
    let id: String
    let name: String
    let author: String
    let character: SoundCharacter
    let version: String
    let sound_format: String
    let key_define_type: String
    let defines: [String: [String]]
    let release_defines: [String: [String]]?
    let spatial_layout: String?
}

enum PackError: Error, CustomStringConvertible {
    case invalidConfig(String)
    case missingSample(String)
    case decodingFailed(String)

    var description: String {
        switch self {
        case .invalidConfig(let m): return "Invalid pack config: \(m)"
        case .missingSample(let p): return "Missing sample: \(p)"
        case .decodingFailed(let p): return "Failed to decode: \(p)"
        }
    }
}
