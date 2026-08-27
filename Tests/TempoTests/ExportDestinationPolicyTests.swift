import Foundation
import XCTest
@testable import Tempo

final class ExportDestinationPolicyTests: XCTestCase {
    func testSuccessfulExportDirectorySurvivesPolicyRelaunch() throws {
        let harness = ExportDestinationHarness()
        defer { harness.reset() }
        let exportDirectory = try TemporaryDirectoryFixture(prefix: "Tempo-export-success")
        defer { exportDirectory.remove() }
        let fallback = try TemporaryDirectoryFixture(prefix: "Tempo-export-fallback")
        defer { fallback.remove() }

        harness.rememberSuccessfulExport(
            at: exportDirectory.url.appendingPathComponent("sessao.mp4")
        )

        XCTAssertEqual(
            harness.preferredDirectoryAfterRelaunch(fallback: fallback.url),
            exportDirectory.url.standardizedFileURL
        )
    }

    func testMissingRememberedDirectoryFallsBackToMoviesDirectory() throws {
        let harness = ExportDestinationHarness()
        defer { harness.reset() }
        let deletedDirectory = try TemporaryDirectoryFixture(prefix: "Tempo-export-deleted")
        let fallback = try TemporaryDirectoryFixture(prefix: "Tempo-movies-fallback")
        defer { fallback.remove() }

        harness.rememberSuccessfulExport(
            at: deletedDirectory.url.appendingPathComponent("sessao.mp4")
        )
        deletedDirectory.remove()

        XCTAssertEqual(
            harness.preferredDirectory(fallback: fallback.url),
            fallback.url
        )
    }

    func testRememberedFileCannotBeUsedAsExportDirectory() throws {
        let harness = ExportDestinationHarness()
        defer { harness.reset() }
        let fixture = try TemporaryDirectoryFixture(prefix: "Tempo-export-file")
        defer { fixture.remove() }
        let fallback = try TemporaryDirectoryFixture(prefix: "Tempo-file-fallback")
        defer { fallback.remove() }
        let invalidDirectory = try fixture.makeFile(named: "nao-e-pasta")

        harness.rememberSuccessfulExport(
            at: invalidDirectory.appendingPathComponent("sessao.mp4")
        )

        XCTAssertEqual(
            harness.preferredDirectory(fallback: fallback.url),
            fallback.url
        )
    }

    func testSuggestedFilenameUsesSessionStartInsteadOfExportTime() throws {
        let harness = ExportDestinationHarness()
        defer { harness.reset() }
        let timeZone = try XCTUnwrap(TimeZone(identifier: "America/Bahia"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let sessionStart = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 27,
            hour: 9,
            minute: 12
        )))
        let exportTime = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 27,
            hour: 17,
            minute: 48
        )))

        XCTAssertEqual(
            harness.suggestedFilename(
                recordingStartedAt: sessionStart,
                fallbackDate: exportTime,
                timeZone: timeZone
            ),
            "Timelapse 2026-08-27 às 09-12.mp4"
        )
    }

    func testSuggestedFilenameFallsBackWhenSessionStartIsUnavailable() throws {
        let harness = ExportDestinationHarness()
        defer { harness.reset() }
        let timeZone = try XCTUnwrap(TimeZone(identifier: "America/Bahia"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let exportTime = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 27,
            hour: 17,
            minute: 48
        )))

        XCTAssertEqual(
            harness.suggestedFilename(
                recordingStartedAt: nil,
                fallbackDate: exportTime,
                timeZone: timeZone
            ),
            "Timelapse 2026-08-27 às 17-48.mp4"
        )
    }
}
