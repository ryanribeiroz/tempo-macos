import Foundation
import XCTest
@testable import Tempo

final class TemporarySessionCleanerTests: XCTestCase {
    func testCleanupPreservesRecentTempoSessionAndRemovesOnlyStaleSession() throws {
        let fixture = try TemporaryDirectoryFixture(prefix: "TempoCleaner")
        defer { fixture.remove() }

        let recentSession = fixture.url.appendingPathComponent("Tempo-recent", isDirectory: true)
        let staleSession = fixture.url.appendingPathComponent("Tempo-stale", isDirectory: true)
        let unrelatedSession = fixture.url.appendingPathComponent("Other-stale", isDirectory: true)
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: recentSession, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: staleSession, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: unrelatedSession, withIntermediateDirectories: true)

        let now = Date(timeIntervalSince1970: 2_000_000)
        try fileManager.setAttributes(
            [.modificationDate: now.addingTimeInterval(-60)],
            ofItemAtPath: recentSession.path
        )
        try fileManager.setAttributes(
            [.modificationDate: now.addingTimeInterval(-TemporarySessionCleaner.maximumSessionAge - 1)],
            ofItemAtPath: staleSession.path
        )
        try fileManager.setAttributes(
            [.modificationDate: now.addingTimeInterval(-TemporarySessionCleaner.maximumSessionAge - 1)],
            ofItemAtPath: unrelatedSession.path
        )

        TemporarySessionCleaner.removeStaleSessions(
            in: fixture.url,
            now: now,
            fileManager: fileManager
        )

        XCTAssertTrue(fileManager.fileExists(atPath: recentSession.path))
        XCTAssertFalse(fileManager.fileExists(atPath: staleSession.path))
        XCTAssertTrue(fileManager.fileExists(atPath: unrelatedSession.path))
    }
}
