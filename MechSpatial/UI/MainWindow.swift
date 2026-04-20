import SwiftUI

struct MainWindow: View {
    @Environment(AppState.self) private var appState
    @State private var tab: Tab = .packs

    enum Tab: Hashable { case packs, position, permissions }

    var body: some View {
        VStack(spacing: 0) {
            if appState.outputDeviceKind == .bluetooth {
                bluetoothBanner
            }
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

    private var bluetoothBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("Bluetooth output adds ~50–250 ms delay. Use wired headphones for instant feel.")
                .font(.caption)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .foregroundStyle(.yellow)
        .background(Color.yellow.opacity(0.12))
        .overlay(
            Rectangle()
                .fill(Color.yellow.opacity(0.4))
                .frame(height: 1),
            alignment: .bottom
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Warning: Bluetooth output adds 50 to 250 milliseconds of latency. Use wired headphones for instant feel.")
    }
}
