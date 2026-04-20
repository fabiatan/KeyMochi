import Testing
@testable import KeyMochi

@Suite("VoicePool")
struct VoicePoolTests {
    @Test("acquire returns each voice exactly once before reuse")
    func fullCycleNoReuse() {
        let pool = VoicePool(capacity: 4)
        let v1 = pool.acquire()
        let v2 = pool.acquire()
        let v3 = pool.acquire()
        let v4 = pool.acquire()
        #expect(Set([v1, v2, v3, v4]).count == 4)
    }

    @Test("acquire past capacity steals oldest (round-robin)")
    func stealOldest() {
        let pool = VoicePool(capacity: 3)
        let v1 = pool.acquire()
        _ = pool.acquire()
        _ = pool.acquire()
        let v4 = pool.acquire()
        #expect(v4 == v1)  // oldest voice index reused first
    }

    @Test("thread safety under rapid acquires")
    func threadSafe() async {
        let pool = VoicePool(capacity: 16)
        await withTaskGroup(of: Int.self) { group in
            for _ in 0..<1000 { group.addTask { pool.acquire() } }
            var allIndices: [Int] = []
            for await i in group { allIndices.append(i) }
            #expect(allIndices.count == 1000)
            #expect(allIndices.allSatisfy { (0..<16).contains($0) })
        }
    }
}
