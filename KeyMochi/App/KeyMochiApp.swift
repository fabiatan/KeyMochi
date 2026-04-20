import Combine
import SwiftUI

@main
struct KeyMochiApp: App {
    @State private var appState = AppState()
    @StateObject private var permissions = PermissionService()
    @StateObject private var coordinatorBox = CoordinatorBox()

    var body: some Scene {
        WindowGroup("KeyMochi", id: "main") {
            MainWindow()
                .environment(appState)
                .environmentObject(permissions)
                .environment(\.packIndex, coordinatorBox.coordinator?.packIndex ?? PackIndex())
                .frame(minWidth: 480, minHeight: 360)
                .task { coordinatorBox.ensure(appState: appState, permissions: permissions) }
                .onChange(of: permissions.isTrusted) { _, _ in
                    coordinatorBox.coordinator?.reactToPermissionChange()
                }
                .onChange(of: appState.isEnabled) { _, v in
                    coordinatorBox.coordinator?.applyEnabled(v)
                }
                .onChange(of: appState.masterVolume) { _, v in
                    coordinatorBox.coordinator?.applyVolume(v)
                }
                .onChange(of: appState.listenerX) { _, _ in
                    coordinatorBox.coordinator?.applyListenerPosition()
                }
                .onChange(of: appState.listenerY) { _, _ in
                    coordinatorBox.coordinator?.applyListenerPosition()
                }
                .onChange(of: appState.listenerZ) { _, _ in
                    coordinatorBox.coordinator?.applyListenerPosition()
                }
                .onChange(of: appState.selectedPackID) { _, _ in
                    coordinatorBox.coordinator?.applySelectedPack()
                }
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarView()
                .environment(appState)
                .environmentObject(permissions)
        } label: {
            Image(systemName: appState.isEnabled ? "keyboard" : "keyboard.badge.ellipsis")
        }
        .menuBarExtraStyle(.window)
    }
}

/// Small holder so the coordinator gets constructed once, lazily, on the
/// first scene's .task. (AppCoordinator requires working AX + AVAudioEngine.)
@MainActor
final class CoordinatorBox: ObservableObject {
    @Published private(set) var coordinator: AppCoordinator?

    func ensure(appState: AppState, permissions: PermissionService) {
        guard coordinator == nil else { return }
        do {
            coordinator = try AppCoordinator(appState: appState, permissions: permissions)
        } catch {
            print("AppCoordinator init failed: \(error)")
        }
    }
}
