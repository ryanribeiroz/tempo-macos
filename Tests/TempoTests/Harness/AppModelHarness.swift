import AppKit
import Foundation
@testable import Tempo

@MainActor
final class AppModelHarness {
    let model: AppModel

    init() {
        self.model = AppModel()
    }

    init(model: AppModel) {
        self.model = model
    }

    func beginSyntheticRecording() {
        model.phase = .recording
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

    func systemWillSleep() {
        postWorkspace(NSWorkspace.willSleepNotification)
    }

    func sessionResignsActive() {
        postWorkspace(NSWorkspace.sessionDidResignActiveNotification)
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
