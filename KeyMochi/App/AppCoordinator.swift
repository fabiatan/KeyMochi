import Foundation
import AVFoundation
import AppKit
import Combine

/// Owns all singletons and wires the hot path together:
/// KeystrokeListener → KeystrokeRouter → SoundPackEngine → AudioGraph.
@MainActor
final class AppCoordinator {
    let appState: AppState
    let permissions: PermissionService
    let packIndex: PackIndex

    private let audioGraph: AudioGraph
    private let sampleCache: AudioSampleCache
    private let engine: SoundPackEngine
    private let router: KeystrokeRouter
    private let listener: KeystrokeListener
    private var auditionTask: Task<Void, Never>?
    let deviceObserver = OutputDeviceObserver()

    init(appState: AppState, permissions: PermissionService) throws {
        self.appState = appState
        self.permissions = permissions
        self.packIndex = PackIndex()

        self.audioGraph = AudioGraph(voiceCount: 16)
        try audioGraph.prepare()
        audioGraph.setMasterVolume(appState.masterVolume)
        audioGraph.setListenerPosition(appState.listenerPosition)

        self.sampleCache = AudioSampleCache()

        let layout = try SpatialLayout.load(id: "qwerty_us")
        // Hot path runs on the CGEventTap background thread:
        // listener.onKeyDownSync → router.ingest → engine.handleSync → graph.fireSync.
        // All three refs are `@unchecked Sendable` classes with internally-locked state.
        let graphRef = audioGraph
        self.engine = SoundPackEngine(
            audioFire: { buf, pos, rate in
                graphRef.fireSync(buffer: buf, at: pos, rateBias: rate)
            },
            layout: layout
        )

        let engineRef = engine
        self.router = KeystrokeRouter(emit: { keyID in
            engineRef.handleSync(keyID: keyID)
        })

        self.listener = KeystrokeListener()
        let routerRef = router
        listener.onKeyDownSync = { keyCode, ts, isRepeat in
            routerRef.ingest(KeyEvent(keyCode: keyCode, timestamp: ts, isRepeat: isRepeat))
        }

        loadBundledPacks()
        selectActivePack()
        wirePackIndex()
        startListeningIfPermitted()
        deviceObserver.start()
        Task { @MainActor [weak self] in
            guard let self else { return }
            for await kind in self.deviceObserver.$kind.values {
                self.appState.outputDeviceKind = kind
            }
        }
    }

    // MARK: - Pack management

    private func loadBundledPacks() {
        guard let packsRoot = Bundle.main.url(
            forResource: "Packs", withExtension: nil) else {
            return
        }
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: packsRoot, includingPropertiesForKeys: nil) else { return }
        for dir in entries where (try? dir.resourceValues(
            forKeys: [.isDirectoryKey]).isDirectory) == true {
            do {
                let pack = try SoundPackLoader.load(from: dir)
                sampleCache.put(pack)
            } catch {
                print("Failed to load pack at \(dir.path): \(error)")
            }
        }
        packIndex.metadata = sampleCache.all.map { pack in
            PackMetadata(
                id: pack.id, name: pack.name,
                character: pack.character,
                description: "Author: \(pack.author) · v\(pack.version)"
            )
        }.sorted { $0.name < $1.name }
    }

    private func selectActivePack() {
        let id = appState.selectedPackID
        if let pack = sampleCache.get(id) {
            engine.setPack(pack)
        } else if let first = sampleCache.all.first {
            engine.setPack(first)
            appState.selectedPackID = first.id
        }
    }

    private func wirePackIndex() {
        packIndex.auditionHandler = { [weak self] id in
            guard let self, let pack = self.sampleCache.get(id) else { return }
            self.auditionTask?.cancel()
            self.engine.setPack(pack)
            self.appState.selectedPackID = id
            self.auditionTask = Task { @MainActor [weak self] in
                self?.engine.handleSync(keyID: .a)
                try? await Task.sleep(for: .milliseconds(120))
                guard !Task.isCancelled else { return }
                self?.engine.handleSync(keyID: .s)
                try? await Task.sleep(for: .milliseconds(120))
                guard !Task.isCancelled else { return }
                self?.engine.handleSync(keyID: .d)
            }
        }
    }

    // MARK: - Listener lifecycle

    private func startListeningIfPermitted() {
        guard permissions.isTrusted else { return }
        do { try listener.start() } catch {
            print("Failed to start listener: \(error)")
        }
    }

    func reactToPermissionChange() {
        if permissions.isTrusted {
            startListeningIfPermitted()
        } else {
            listener.stop()
        }
    }

    func applyEnabled(_ enabled: Bool) {
        audioGraph.setMasterVolume(enabled ? appState.masterVolume : 0)
    }

    func applyVolume(_ v: Float) {
        audioGraph.setMasterVolume(appState.isEnabled ? v : 0)
    }

    func applyListenerPosition() {
        audioGraph.setListenerPosition(appState.listenerPosition)
    }

    func applySelectedPack() {
        if let pack = sampleCache.get(appState.selectedPackID) {
            engine.setPack(pack)
        }
    }
}
