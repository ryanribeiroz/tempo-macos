import AVFoundation
import Foundation
import XCTest
@testable import Tempo

final class VideoExporterTests: XCTestCase {
    func testPixelBufferPreservesVerticalOrientation() throws {
        let image = try VideoFrameFixture.topRedBottomBlueImage(width: 8, height: 8)
        let buffer = try PixelBufferHarness.makeBGRA(width: 8, height: 8)

        try VideoExporter.draw(image, into: buffer)

        let topPixel = try PixelBufferHarness.bgraPixel(in: buffer, x: 0, y: 0)
        let bottomPixel = try PixelBufferHarness.bgraPixel(in: buffer, x: 0, y: 7)

        XCTAssertGreaterThan(topPixel[2], 240, "O topo do quadro deve continuar vermelho")
        XCTAssertLessThan(topPixel[0], 15)
        XCTAssertGreaterThan(bottomPixel[0], 240, "A base do quadro deve continuar azul")
        XCTAssertLessThan(bottomPixel[2], 15)
    }

    func testCreatesPlayableH264Video() async throws {
        guard ProcessInfo.processInfo.environment["TEMPO_RUN_ENCODER_TESTS"] == "1" else {
            throw XCTSkip("Requer o encoder H.264 fora do sandbox. Execute TEMPO_RUN_ENCODER_TESTS=1 Scripts/test.sh.")
        }
        let directory = try TemporaryDirectoryFixture(prefix: "TempoExporterTest")
        defer { directory.remove() }
        let frames = try VideoFrameFixture.makeJPEGSequence(count: 3, in: directory.url)
        let output = directory.url.appendingPathComponent("test.mp4")

        try await VideoExporter().export(frames: frames, to: output, quality: .light) { _ in }

        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
        XCTAssertGreaterThan((try FileManager.default.attributesOfItem(atPath: output.path)[.size] as? NSNumber)?.intValue ?? 0, 0)
        let asset = AVURLAsset(url: output)
        let duration = try await asset.load(.duration)
        XCTAssertGreaterThan(duration.seconds, 0)
        XCTAssertLessThanOrEqual(duration.seconds, 0.11)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        XCTAssertEqual(tracks.count, 1)
    }
}
