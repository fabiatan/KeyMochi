import SwiftUI

struct MainWindow: View {
    @Environment(AppState.self) private var appState
    @State private var tab: Tab = .packs

    enum Tab: Hashable { case packs, position, permissions }

    var body: some View {
        TabView(selection: $tab) {
            PackPickerView()
                .tabItem { Label("Packs", systemImage: "speaker.wave.3.fill") }
                .tag(Tab.packs)
            SpatialPositionView()
                .tabItem { Label("Position", systemImage: "scope") }
                .tag(Tab.position)
            PermissionOnboardingView()
                .tabItem { Label("Permissions", systemImage: "checkmark.shield") }
                .tag(Tab.permissions)
        }
        .padding()
    }
}
