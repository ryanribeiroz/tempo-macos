import Foundation

struct ExportDestinationPolicy {
    static let lastSuccessfulDirectoryKey = "TempoLastSuccessfulExportDirectory"

    private let defaults: UserDefaults
    private let fileManager: FileManager

    init(
        defaults: UserDefaults = .standard,
        fileManager: FileManager = .default
    ) {
        self.defaults = defaults
        self.fileManager = fileManager
    }

    func preferredDirectory(fallback: URL?) -> URL? {
        guard let path = defaults.string(forKey: Self.lastSuccessfulDirectoryKey) else {
            return fallback
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return fallback
        }

        return URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
    }

    func rememberSuccessfulExport(at outputURL: URL) {
        let directory = outputURL
            .deletingLastPathComponent()
            .standardizedFileURL
        defaults.set(directory.path, forKey: Self.lastSuccessfulDirectoryKey)
    }

    func suggestedFilename(
        recordingStartedAt: Date?,
        fallbackDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd 'às' HH-mm"
        let date = recordingStartedAt ?? fallbackDate
        return "Timelapse \(formatter.string(from: date)).mp4"
    }
}
