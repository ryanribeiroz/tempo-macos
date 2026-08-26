import CoreVideo
import Foundation
@testable import Tempo

enum PixelBufferHarness {
    static func makeBGRA(width: Int, height: Int) throws -> CVPixelBuffer {
        var optionalBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        let status = CVPixelBufferCreate(
            nil,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &optionalBuffer
        )
        guard status == kCVReturnSuccess, let buffer = optionalBuffer else {
            throw TempoError.videoSetupFailed("fixture de pixel buffer indisponível")
        }
        return buffer
    }

    static func bgraPixel(in buffer: CVPixelBuffer, x: Int, y: Int) throws -> [UInt8] {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            throw TempoError.videoSetupFailed("buffer de teste inválido")
        }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let offset = y * bytesPerRow + x * 4
        let pixel = baseAddress.assumingMemoryBound(to: UInt8.self) + offset
        return Array(UnsafeBufferPointer(start: pixel, count: 4))
    }
}
