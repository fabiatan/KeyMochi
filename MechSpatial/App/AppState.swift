import Foundation
import Observation
import AVFoundation

enum OutputDeviceKind: String, Sendable {
    case wired
    case bluetooth
    case builtInSpeaker
    case unknown
}

@Observable
@MainActor
final class AppState {
    var isEnabled: Bool {
        didSet { save() }
    }

    var selectedPackID: String {
        didSet { save() }
    }

    var masterVolume: Float {
        didSet { save() }
    }

    /// Listener position (meters) in the HRTF scene. Default: origin.
    var listenerX: Float {
        didSet { save() }
    }
    var listenerY: Float {
        didSet { save() }
    }
    var listenerZ: Float {
        didSet { save() }
    }

    var permissionGranted: Bool = false
    var outputDeviceKind: OutputDeviceKind = .unknown

    var listenerPosition: AVAudio3DPoint {
        AVAudio3DPoint(x: listenerX, y: listenerY, z: listenerZ)
    }

    private enum Key {
        static let isEnabled = "mechspatial.isEnabled"
        static let selectedPackID = "mechspatial.selectedPackID"
        static let masterVolume = "mechspatial.masterVolume"
        static let listenerX = "mechspatial.listenerX"
        static let listenerY = "mechspatial.listenerY"
        static let listenerZ = "mechspatial.listenerZ"
    }

    init() {
        let d = UserDefaults.standard
        self.isEnabled = d.object(forKey: Key.isEnabled) as? Bool ?? true
        self.selectedPackID = d.string(forKey: Key.selectedPackID) ?? "clacky"
        self.masterVolume = d.object(forKey: Key.masterVolume) as? Float ?? 0.7
        self.listenerX = d.object(forKey: Key.listenerX) as? Float ?? 0.0
        self.listenerY = d.object(forKey: Key.listenerY) as? Float ?? 0.0
        self.listenerZ = d.object(forKey: Key.listenerZ) as? Float ?? 0.0
    }

    private func save() {
        let d = UserDefaults.standard
        d.set(isEnabled, forKey: Key.isEnabled)
        d.set(selectedPackID, forKey: Key.selectedPackID)
        d.set(masterVolume, forKey: Key.masterVolume)
        d.set(listenerX, forKey: Key.listenerX)
        d.set(listenerY, forKey: Key.listenerY)
        d.set(listenerZ, forKey: Key.listenerZ)
    }
}
