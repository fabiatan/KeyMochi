import Foundation
import AVFoundation

enum SoundPackLoader {
    /// Parse the pack's config.json. Does not load samples.
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
}
