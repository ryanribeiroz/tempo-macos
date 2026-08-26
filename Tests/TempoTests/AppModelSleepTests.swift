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

    func testResumeWaitsForEverySystemInterruptionToRecover() async throws {
        let harness = AppModelHarness()
        harness.beginSyntheticRecording(frameCount: 224)
        harness.screensSleep()
        harness.systemWillSleep()
        harness.sessionResignsActive()
        try await harness.settle()

        XCTAssertEqual(harness.model.phase, .paused(.screensAsleep))
        XCTAssertEqual(harness.model.frameCount, 224)

        harness.screensWake()
        try await harness.settle()
        XCTAssertFalse(harness.model.canResume)
        XCTAssertFalse(harness.model.showResumePrompt)

        harness.resumeRecording()
        try await harness.settle()
        let prematureStartCount = await harness.captureLoopStartCount()
        XCTAssertEqual(harness.model.phase, .paused(.screensAsleep))
        XCTAssertEqual(prematureStartCount, 0)

        harness.systemDidWake()
        try await harness.settle()
        XCTAssertFalse(harness.model.canResume)

        harness.sessionBecomesActive()
        try await harness.settle()
        XCTAssertTrue(harness.model.canResume)
        XCTAssertTrue(harness.model.showResumePrompt)

        harness.resumeRecording()
        try await harness.settle()
        let resumedStartCount = await harness.captureLoopStartCount()
        XCTAssertEqual(harness.model.phase, .recording)
        XCTAssertEqual(resumedStartCount, 1)
    }
}
