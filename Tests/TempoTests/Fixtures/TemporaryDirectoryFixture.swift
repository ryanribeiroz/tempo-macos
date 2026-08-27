import Foundation

struct TemporaryDirectoryFixture {
    let url: URL

    init(prefix: String) throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func remove() {
        try? FileManager.default.removeItem(at: url)
    }

    func makeFile(named name: String, contents: Data = Data()) throws -> URL {
        let fileURL = url.appendingPathComponent(name, isDirectory: false)
        try contents.write(to: fileURL)
        return fileURL
    }
}
