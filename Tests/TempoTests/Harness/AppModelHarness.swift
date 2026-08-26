import AppKit
import Foundation
@testable import Tempo

@MainActor
final class AppModelHarness {
    let model: AppModel
    private let captureSession: CaptureSessionHarness?

    init(
        captureOutcomes: [CaptureSessionHarness.Outcome] = [.success],
        maximumConsecutiveCaptureFailures: Int = 5
    ) {
        let captureSession = CaptureSessionHarness(outcomes: captureOutcomes)
        self.captureSession = captureSession
        self.model = AppModel(
            session: captureSession,
            maximumConsecutiveCaptureFailures: maximumConsecutiveCaptureFailures,
            captureRetryBaseDelayNanoseconds: 1_000_000
        )
    }

    init(model: AppModel) {
        self.captureSession = nil
        self.model = model
    }

    func beginSyntheticRecording(frameCount: Int = 0) {
        model.phase = .recording
        model.frameCount = frameCount
    }

    func pauseManually() {
        model.pauseManually()
    }

    func screensSleep() {
        postWorkspace(NSWorkspace.screensDidSleepNotification)
    }

    func screensWake() {
        postWorkspace(NSWorkspace.screensDidWakeNotification)
    }

    func systemDidWake() {
        postWorkspace(NSWorkspace.didWakeNotification)
    }

    func systemWillSleep() {
        postWorkspace(NSWorkspace.willSleepNotification)
    }

    func sessionResignsActive() {
        postWorkspace(NSWorkspace.sessionDidResignActiveNotification)
    }

    func sessionBecomesActive() {
        postWorkspace(NSWorkspace.sessionDidBecomeActiveNotification)
    }

    func resumeRecording() {
        model.resumeRecording()
    }

    func captureLoopStartCount() async -> Int {
        await captureSession?.startCount() ?? 0
    }

    func settle() async throws {
        try await Task.sleep(nanoseconds: 30_000_000)
    }

    private func postWorkspace(_ name: Notification.Name) {
        NSWorkspace.shared.notificationCenter.post(
            name: name,
            object: NSWorkspace.shared
        )
    }
}

actor CaptureSessionHarness: CaptureSessionProtocol {
    enum Outcome: Sendable {
        case failure
        case success
        case successThenFailure
    }

    enum HarnessError: LocalizedError {
        case captureUnavailable

        var errorDescription: String? {
            "Captura temporariamente indisponível no harness."
        }
    }

    private var starts = 0
    private var outcomes: [Outcome]

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func run(onUpdate: @escaping @Sendable (Int, TimeInterval) async -> Void) async throws {
        starts += 1
        let outcome = outcomes.isEmpty ? .success : outcomes.removeFirst()
        switch outcome {
        case .failure:
            throw HarnessError.captureUnavailable
        case .success:
            await onUpdate(1, 2)
        case .successThenFailure:
            await onUpdate(1, 2)
            throw HarnessError.captureUnavailable
        }
    }

    func stop() -> CaptureSnapshot {
        CaptureSnapshot(frameURLs: [], directory: FileManager.default.temporaryDirectory)
    }

    func discard() {}

    func startCount() -> Int {
        starts
    }
}
