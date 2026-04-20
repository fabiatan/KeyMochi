import Testing
@testable import MechSpatial

@Suite("PermissionService")
@MainActor
struct PermissionServiceTests {
    @Test("reports current trust state from dependency")
    func currentState() {
        let stub = StubAXTrust(trusted: true)
        let service = PermissionService(axTrust: stub)
        #expect(service.isTrusted == true)
    }

    @Test("transitions to trusted when poll flips")
    func transitionToTrusted() async {
        let stub = StubAXTrust(trusted: false)
        let service = PermissionService(axTrust: stub, pollInterval: 0.05)
        #expect(service.isTrusted == false)
        service.startPolling()
        try? await Task.sleep(nanoseconds: 50_000_000)
        stub.trusted = true
        try? await Task.sleep(nanoseconds: 150_000_000)
        #expect(service.isTrusted == true)
        service.stopPolling()
    }
}

final class StubAXTrust: AXTrustChecking, @unchecked Sendable {
    var trusted: Bool
    init(trusted: Bool) { self.trusted = trusted }
    func isProcessTrusted() -> Bool { trusted }
    func promptTrust() {}
}
