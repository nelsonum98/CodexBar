import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

struct TestStoreScratchTests {
    @Test
    func `shared fixture stores stay inside runner scratch`() throws {
        let temporaryPath = try #require(ProcessInfo.processInfo.environment["TMPDIR"])
        let root = URL(fileURLWithPath: temporaryPath, isDirectory: true).resolvingSymlinksInPath().path + "/"
        let suite = "TestStoreScratch-\(UUID().uuidString)"
        let config = testConfigStore(suiteName: suite)
        let history = testPlanUtilizationHistoryStore(suiteName: suite)
        let historical = HistoricalUsagePaceTests.makeTempURL()

        #expect(config.fileURL.resolvingSymlinksInPath().path.hasPrefix(root))
        #expect(try #require(history.directoryURL).resolvingSymlinksInPath().path.hasPrefix(root))
        #expect(historical.resolvingSymlinksInPath().path.hasPrefix(root))
        try config.save(.makeDefault())
        #expect(FileManager.default.fileExists(atPath: config.fileURL.path))
    }
}
