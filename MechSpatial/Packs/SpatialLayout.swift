import Foundation
import AVFoundation

struct SpatialPosition: Decodable, Sendable {
    let x: Float
    let y: Float
    let z: Float
    var audio3D: AVAudio3DPoint { .init(x: x, y: y, z: z) }
}

struct SpatialLayout: Sendable {
    let id: String
    let version: String
    private let positions: [KeyID: SpatialPosition]

    func position(for key: KeyID) -> AVAudio3DPoint? {
        positions[key]?.audio3D
    }

    /// Load a layout by id from the app bundle (Resources/Layouts/<id>.json).
    static func load(id: String) throws -> SpatialLayout {
        guard let url = Bundle.main.url(
            forResource: id, withExtension: "json", subdirectory: "Layouts"
        ) else {
            throw PackError.invalidConfig("Layout \(id) not found in bundle")
        }
        let data = try Data(contentsOf: url)
        let raw = try JSONDecoder().decode(RawLayout.self, from: data)
        var positions: [KeyID: SpatialPosition] = [:]
        for (keyString, pos) in raw.keys {
            if let keyID = KeyID(rawValue: keyString) {
                positions[keyID] = pos
            }
        }
        return SpatialLayout(id: raw.id, version: raw.version, positions: positions)
    }

    private struct RawLayout: Decodable {
        let id: String
        let version: String
        let keys: [String: SpatialPosition]
    }
}
