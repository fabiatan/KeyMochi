import SwiftUI

@main
struct MechSpatialApp: App {
    @State private var appState = AppState()
    @StateObject private var permissions = PermissionService()

    var body: some Scene {
        WindowGroup("MechSpatial", id: "main") {
            MainWindow()
                .environment(appState)
                .environmentObject(permissions)
                .frame(minWidth: 480, minHeight: 360)
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
