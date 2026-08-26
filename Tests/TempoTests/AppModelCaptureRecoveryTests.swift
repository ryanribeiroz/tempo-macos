import XCTest
@testable import Tempo

@MainActor
final class AppModelCaptureRecoveryTests: XCTestCase {
    func testTransientFailuresRecoverBeforePausing() async throws {
        let harness = AppModelHarness(captureOutcomes: [.failure, .failure, .success])
        harness.beginSyntheticRecording()
        harness.pauseManually()

        XCTAssertEqual(harness.model.recordingDuration(), 0, accuracy: 0.001)
        XCTAssertFalse(harness.model.canExport)

        harness.resumeRecording()
        try await harness.settle()

        let startCount = await harness.captureLoopStartCount()
        XCTAssertEqual(startCount, 3)
        XCTAssertEqual(harness.model.phase, .recording)
        XCTAssertEqual(harness.model.frameCount, 1)
        XCTAssertTrue(harness.model.canExport)
        XCTAssertGreaterThan(harness.model.recordingDuration(), 0)
        XCTAssertNil(harness.model.lastCaptureErrorMessage)
    }

    func testPersistentFailuresPauseWithDiagnosticAndNoFakeDuration() async throws {
        let harness = AppModelHarness(
            captureOutcomes: [.failure, .failure, .failure],
            maximumConsecutiveCaptureFailures: 3
        )
        harness.beginSyntheticRecording()
        harness.pauseManually()
        harness.resumeRecording()
        try await harness.settle()

        let startCount = await harness.captureLoopStartCount()
        XCTAssertEqual(startCount, 3)
        XCTAssertEqual(harness.model.phase, .paused(.captureInterrupted))
        XCTAssertEqual(harness.model.frameCount, 0)
        XCTAssertEqual(harness.model.recordingDuration(), 0, accuracy: 0.001)
        XCTAssertFalse(harness.model.canExport)
        XCTAssertNotNil(harness.model.lastCaptureErrorMessage)
    }

    func testSuccessfulFrameResetsConsecutiveFailureCount() async throws {
        let harness = AppModelHarness(
            captureOutcomes: [.failure, .successThenFailure, .failure, .success],
            maximumConsecutiveCaptureFailures: 3
        )
        harness.beginSyntheticRecording()
        harness.pauseManually()
        harness.resumeRecording()
        try await harness.settle()

        let startCount = await harness.captureLoopStartCount()
        XCTAssertEqual(startCount, 4)
        XCTAssertEqual(harness.model.phase, .recording)
        XCTAssertEqual(harness.model.frameCount, 1)
        XCTAssertTrue(harness.model.canExport)
    }
}
