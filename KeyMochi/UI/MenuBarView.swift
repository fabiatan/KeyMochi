import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @EnvironmentObject private var permissions: PermissionService

    var body: some View {
        @Bindable var appState = appState
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Enabled", isOn: $appState.isEnabled)
                .disabled(!permissions.isTrusted)
            Divider()
            Text("Pack: \(appState.selectedPackID)").foregroundStyle(.secondary)
            HStack {
                Image(systemName: "speaker.fill")
                Slider(value: $appState.masterVolume, in: 0...1)
                Image(systemName: "speaker.wave.3.fill")
            }
            Divider()
            Button("Open Main Window…") { openMainWindow() }
                .keyboardShortcut(",", modifiers: [.command])
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q", modifiers: [.command])
        }
        .padding(12)
        .frame(width: 240)
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: { $0.title == "KeyMochi" })?.makeKeyAndOrderFront(nil)
    }
}
