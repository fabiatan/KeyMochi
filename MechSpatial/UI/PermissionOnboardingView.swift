import SwiftUI
import AppKit

struct PermissionOnboardingView: View {
    @EnvironmentObject private var permissions: PermissionService
    @State private var showRelaunchPrompt = false

    var body: some View {
        VStack(spacing: 16) {
            if permissions.isTrusted {
                grantedView
            } else {
                ungrantedView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .task { permissions.startPolling() }
        .onChange(of: permissions.isTrusted) { _, newValue in
            if newValue { showRelaunchPrompt = true }
        }
        .alert("Permission granted — restart to continue",
               isPresented: $showRelaunchPrompt) {
            Button("Restart Now", action: relaunchApp)
            Button("Later", role: .cancel) { }
        } message: {
            Text("MechSpatial needs to restart to start listening to keystrokes.")
        }
    }

    private var ungrantedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text("Accessibility Permission Needed")
                .font(.title2).bold()
            Text("MechSpatial needs to observe your keystrokes to play matching keyboard sounds. This is handled entirely on-device.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Grant Accessibility Access") {
                permissions.requestWithPrompt()
                permissions.openSystemSettings()
            }
            .buttonStyle(.borderedProminent)
            Text("Toggle MechSpatial on in System Settings → Privacy & Security → Accessibility.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var grantedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            Text("Accessibility Granted").font(.title2).bold()
            Text("MechSpatial is listening. Type to hear it.")
                .foregroundStyle(.secondary)
            Link("How to revoke this permission",
                 destination: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                .font(.caption)
        }
    }

    private func relaunchApp() {
        let url = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config)
        NSApp.terminate(nil)
    }
}
