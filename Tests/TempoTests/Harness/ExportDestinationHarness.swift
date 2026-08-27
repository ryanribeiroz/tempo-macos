import Foundation
@testable import Tempo

struct ExportDestinationHarness {
    let suiteName: String
    private let defaults: UserDefaults

    init() {
        suiteName = "TempoTests.ExportDestination.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    func preferredDirectory(fallback: URL?) -> URL? {
        makePolicy().preferredDirectory(fallback: fallback)
    }

    func rememberSuccessfulExport(at outputURL: URL) {
        makePolicy().rememberSuccessfulExport(at: outputURL)
    }

    func preferredDirectoryAfterRelaunch(fallback: URL?) -> URL? {
        ExportDestinationPolicy(
            defaults: UserDefaults(suiteName: suiteName)!
        ).preferredDirectory(fallback: fallback)
    }

    func suggestedFilename(
        recordingStartedAt: Date?,
        fallbackDate: Date,
        timeZone: TimeZone
    ) -> String {
        makePolicy().suggestedFilename(
            recordingStartedAt: recordingStartedAt,
            fallbackDate: fallbackDate,
            timeZone: timeZone
        )
    }

    func reset() {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func makePolicy() -> ExportDestinationPolicy {
        ExportDestinationPolicy(defaults: defaults)
    }
}
