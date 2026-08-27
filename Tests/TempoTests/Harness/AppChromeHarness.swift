import Foundation
@testable import Tempo

struct AppChromeHarness {
    func shouldMinimize(from oldPhase: AppPhase, to newPhase: AppPhase) -> Bool {
        AppChromePolicy.shouldMinimize(from: oldPhase, to: newPhase)
    }

    func presentation(
        for phase: AppPhase,
        frameCount: Int = 0,
        recordingDuration: TimeInterval = 0
    ) -> MenuBarPresentation {
        AppChromePolicy.presentation(
            for: phase,
            frameCount: frameCount,
            recordingDuration: recordingDuration
        )
    }

    func actions(
        for phase: AppPhase,
        canExport: Bool = false,
        canResume: Bool = false
    ) -> [MenuBarAction] {
        AppChromePolicy.actions(
            for: phase,
            canExport: canExport,
            canResume: canResume
        )
    }
}
