import Foundation
import CoreAudio
import AVFoundation
import Combine

@MainActor
final class OutputDeviceObserver: ObservableObject {
    @Published private(set) var kind: OutputDeviceKind = .unknown
    private var listenerProc: AudioObjectPropertyListenerProc?

    init() { refresh() }

    func start() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            DispatchQueue.main
        ) { [weak self] _, _ in
            self?.refresh()
        }
    }

    func refresh() {
        let deviceID = defaultOutputDeviceID() ?? 0
        let transport = transportType(of: deviceID)
        self.kind = classify(transport: transport, deviceID: deviceID)
    }

    private func defaultOutputDeviceID() -> AudioDeviceID? {
        var id = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &addr, 0, nil, &size, &id)
        return status == noErr ? id : nil
    }

    private func transportType(of device: AudioDeviceID) -> UInt32 {
        var transport = UInt32(0)
        var size = UInt32(MemoryLayout<UInt32>.size)
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        AudioObjectGetPropertyData(device, &addr, 0, nil, &size, &transport)
        return transport
    }

    private func classify(transport: UInt32, deviceID: AudioDeviceID) -> OutputDeviceKind {
        switch transport {
        case kAudioDeviceTransportTypeBluetooth,
             kAudioDeviceTransportTypeBluetoothLE:
            return .bluetooth
        case kAudioDeviceTransportTypeBuiltIn:
            return .builtInSpeaker
        case kAudioDeviceTransportTypeUSB,
             kAudioDeviceTransportTypeFireWire,
             kAudioDeviceTransportTypeThunderbolt,
             kAudioDeviceTransportTypeAggregate,
             kAudioDeviceTransportTypeVirtual,
             kAudioDeviceTransportTypeHDMI,
             kAudioDeviceTransportTypeDisplayPort,
             kAudioDeviceTransportTypeAirPlay:
            return .wired
        default:
            return .unknown
        }
    }
}
