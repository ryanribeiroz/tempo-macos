import XCTest
@testable import Tempo

@MainActor
final class AppModelSleepTests: XCTestCase {
    func testScreenSleepPausesAndWakeRequiresConfirmation() async throws {
        let harness = AppModelHarness()
        harness.beginSyntheticRecording()
        harness.screensSleep()
        try await harness.settle()

        XCTAssertEqual(harness.model.phase, .paused(.screensAsleep))
        XCTAssertFalse(harness.model.showResumePrompt)

        harness.screensWake()
        try await harness.settle()

        XCTAssertTrue(harness.model.showResumePrompt)
        XCTAssertEqual(harness.model.phase, .paused(.screensAsleep))
    }

    func testManualPauseDoesNotAskToResumeAfterWake() async throws {
        let harness = AppModelHarness()
        harness.beginSyntheticRecording()
        harness.pauseManually()
        harness.screensWake()
        try await harness.settle()

        XCTAssertEqual(harness.model.phase, .paused(.manual))
        XCTAssertFalse(harness.model.showResumePrompt)
    }
}
