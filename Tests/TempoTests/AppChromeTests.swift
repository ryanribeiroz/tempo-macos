import SwiftUI
import XCTest
@testable import Tempo

final class AppChromeTests: XCTestCase {
    private let harness = AppChromeHarness()

    func testOnlyInitialRecordingTransitionMinimizesWindow() {
        XCTAssertTrue(harness.shouldMinimize(from: .requestingPermission, to: .recording))
        XCTAssertFalse(harness.shouldMinimize(from: .paused(.manual), to: .recording))
        XCTAssertFalse(harness.shouldMinimize(from: .idle, to: .requestingPermission))
    }

    func testMenuBarPresentationReflectsRecordingPhase() {
        let recording = harness.presentation(for: .recording, frameCount: 224, recordingDuration: 3_661.9)
        XCTAssertEqual(recording.status, "Gravando • 01:01:01")
        XCTAssertEqual(recording.systemImage, "record.circle.fill")

        let paused = harness.presentation(for: .paused(.manual), recordingDuration: 62)
        XCTAssertEqual(paused.status, "Pausada • 00:01:02")
        XCTAssertEqual(paused.systemImage, "pause.circle.fill")
    }

    func testDurationFormatterUsesClockFormatAndDoesNotShowNegativeTime() {
        XCTAssertEqual(AppChromePolicy.formattedDuration(0), "00:00:00")
        XCTAssertEqual(AppChromePolicy.formattedDuration(86_399), "23:59:59")
        XCTAssertEqual(AppChromePolicy.formattedDuration(-1), "00:00:00")
    }

    func testMenuActionsRespectFramesAndResumeAvailability() {
        XCTAssertEqual(
            harness.actions(for: .recording, canExport: true),
            [.open, .pause, .stopAndExport, .quit]
        )
        XCTAssertEqual(
            harness.actions(for: .recording, canExport: false),
            [.open, .pause, .cancel, .quit]
        )
        XCTAssertEqual(
            harness.actions(for: .paused(.systemSleep), canExport: true, canResume: false),
            [.open, .stopAndExport, .quit]
        )
        XCTAssertEqual(
            harness.actions(for: .paused(.systemSleep), canExport: true, canResume: true),
            [.open, .resume, .stopAndExport, .quit]
        )
    }

    func testAppearanceModesHaveStablePersistenceValues() {
        XCTAssertEqual(AppearanceMode.allCases.map(\.rawValue), ["system", "light", "dark"])
        XCTAssertNil(AppearanceMode.system.colorScheme)
        XCTAssertEqual(AppearanceMode.light.colorScheme, .light)
        XCTAssertEqual(AppearanceMode.dark.colorScheme, .dark)
    }
}
