import Foundation
import ApplicationServices
import AppKit
import Combine

protocol AXTrustChecking: Sendable {
    func isProcessTrusted() -> Bool
    func promptTrust()
}

struct SystemAXTrust: AXTrustChecking {
    func isProcessTrusted() -> Bool { AXIsProcessTrusted() }
    func promptTrust() {
        let key = "AXTrustedCheckOptionPrompt"
        let opts = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }
}

@MainActor
final class PermissionService: ObservableObject {
    @Published private(set) var isTrusted: Bool
    private let axTrust: AXTrustChecking
    private let pollInterval: TimeInterval
    private var pollTask: Task<Void, Never>?

    init(axTrust: AXTrustChecking = SystemAXTrust(),
         pollInterval: TimeInterval = 1.0) {
        self.axTrust = axTrust
        self.pollInterval = pollInterval
        self.isTrusted = axTrust.isProcessTrusted()
    }

    nonisolated func requestWithPrompt() {
        axTrust.promptTrust()
    }

    nonisolated func openSystemSettings() {
        let urlStr = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlStr) {
            DispatchQueue.main.async { NSWorkspace.shared.open(url) }
        }
    }

    func startPolling() {
        stopPolling()
        pollTask = Task { [weak self, axTrust, pollInterval] in
            while !Task.isCancelled {
                let now = axTrust.isProcessTrusted()
                await MainActor.run {
                    guard let self else { return }
                    if self.isTrusted != now { self.isTrusted = now }
                }
                try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1e9))
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }
}
