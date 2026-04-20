import Foundation
import AVFoundation

/// Character label for a sound pack — free-form string that categorises
/// the typing feel (e.g. "cherrymx-brown-pbt", "clacky"). Packs choose their
/// own value; the UI derives a card colour from a stable hash so new values
/// work without code changes.
typealias SoundCharacter = String

/// Round-robin variant set for a single key action (press or release).
struct SampleSet: Sendable {
    /// Variant buffers (pre-decoded PCM). Non-empty.
    let variants: [AVAudioPCMBuffer]
}

/// A loaded sound pack. `press` and `release` map KeyID → variants;
/// `release` is empty for packs without release samples.
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
