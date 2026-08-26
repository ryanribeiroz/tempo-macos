import CoreGraphics
import Foundation
import ImageIO
import ScreenCaptureKit
import UniformTypeIdentifiers

actor CaptureSession {
    struct Snapshot {
        let frameURLs: [URL]
        let directory: URL
    }

    private let directory: URL
    private let quality: OutputQuality
    private var sampler = FrameSampler()
    private var frameURLs: [URL] = []
    private var sequence = 0
    private var running = false

    init(quality: OutputQuality) throws {
        self.quality = quality
        self.directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Tempo-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    static func verifyAccess() async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        guard !content.displays.isEmpty else { throw TempoError.noDisplays }
    }

    func run(onUpdate: @escaping @Sendable (Int, TimeInterval) async -> Void) async throws {
        running = true

        while running && !Task.isCancelled {
            let image = try await Self.captureComposite(quality: quality)
            let url = directory.appendingPathComponent(String(format: "frame-%08d.jpg", sequence))
            try Self.writeJPEG(image, to: url, quality: quality.jpegQuality)
            sequence += 1
            frameURLs.append(url)

            if let keptIndices = sampler.indicesToKeep(afterAppending: frameURLs.count) {
                let kept = Set(keptIndices)
                for (index, oldURL) in frameURLs.enumerated() where !kept.contains(index) {
                    try? FileManager.default.removeItem(at: oldURL)
                }
                frameURLs = keptIndices.map { frameURLs[$0] }
            }

            await onUpdate(frameURLs.count, sampler.interval)
            try await Task.sleep(nanoseconds: UInt64(sampler.interval * 1_000_000_000))
        }
    }

    func stop() -> Snapshot {
        running = false
        return Snapshot(frameURLs: frameURLs, directory: directory)
    }

    func discard() {
        running = false
        try? FileManager.default.removeItem(at: directory)
        frameURLs.removeAll()
    }

    private static func captureComposite(quality: OutputQuality) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        guard !content.displays.isEmpty else { throw TempoError.noDisplays }

        let ownBundleID = Bundle.main.bundleIdentifier
        let ownApplications = content.applications.filter { $0.bundleIdentifier == ownBundleID }
        let displays = content.displays.sorted { $0.displayID < $1.displayID }
        let union = displays.map(\.frame).reduce(CGRect.null) { $0.union($1) }
        let maxSize = quality.maximumSize
        let scale = min(maxSize.width / union.width, maxSize.height / union.height)
        let width = Self.evenPixelCount(union.width * scale)
        let height = Self.evenPixelCount(union.height * scale)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw TempoError.contextCreationFailed
        }

        context.setFillColor(CGColor(red: 0.035, green: 0.05, blue: 0.08, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.interpolationQuality = .high

        for display in displays {
            let filter = SCContentFilter(
                display: display,
                excludingApplications: ownApplications,
                exceptingWindows: []
            )
            let configuration = SCStreamConfiguration()
            configuration.width = Int((display.frame.width * scale).rounded(.up))
            configuration.height = Int((display.frame.height * scale).rounded(.up))
            configuration.showsCursor = true
            configuration.capturesAudio = false

            let screenshot = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )
            let x = (display.frame.minX - union.minX) * scale
            let yFromTop = (display.frame.minY - union.minY) * scale
            let destination = CGRect(
                x: x,
                y: CGFloat(height) - yFromTop - display.frame.height * scale,
                width: display.frame.width * scale,
                height: display.frame.height * scale
            )
            context.draw(screenshot, in: destination)
        }

        guard let image = context.makeImage() else { throw TempoError.captureFailed }
        return image
    }

    private static func evenPixelCount(_ value: CGFloat) -> Int {
        let rounded = max(2, Int(value.rounded(.down)))
        return rounded.isMultiple(of: 2) ? rounded : rounded - 1
    }

    private static func writeJPEG(_ image: CGImage, to url: URL, quality: CGFloat) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw TempoError.imageWriteFailed
        }
        CGImageDestinationAddImage(
            destination,
            image,
            [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else { throw TempoError.imageWriteFailed }
    }
}
