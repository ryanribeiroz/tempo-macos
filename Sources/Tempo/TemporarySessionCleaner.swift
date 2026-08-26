import Foundation

struct TemporarySessionCleaner {
    static let maximumSessionAge: TimeInterval = 24 * 60 * 60

    static func removeStaleSessions(
        in parentDirectory: URL,
        now: Date = Date(),
        fileManager: FileManager = .default
    ) {
        guard let items = try? fileManager.contentsOfDirectory(
            at: parentDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let cutoff = now.addingTimeInterval(-maximumSessionAge)
        for item in items where item.lastPathComponent.hasPrefix("Tempo-") {
            guard let values = try? item.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modificationDate = values.contentModificationDate,
                  modificationDate < cutoff else { continue }
            try? fileManager.removeItem(at: item)
        }
    }
}
