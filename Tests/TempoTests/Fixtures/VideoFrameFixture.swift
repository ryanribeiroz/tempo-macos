import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
@testable import Tempo

enum VideoFrameFixture {
    private static let colors: [CGColor] = [
        CGColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1),
        CGColor(red: 0.2, green: 0.7, blue: 0.6, alpha: 1),
        CGColor(red: 0.9, green: 0.25, blue: 0.2, alpha: 1)
    ]

    static func makeJPEGSequence(count: Int, in directory: URL) throws -> [URL] {
        try (0..<count).map { index in
            let url = directory.appendingPathComponent("\(index).jpg")
            try makeSolidJPEG(index: index, at: url)
            return url
        }
    }

    static func topRedBottomBlueImage(width: Int, height: Int) throws -> CGImage {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                if y < height / 2 {
                    pixels[offset] = 255
                } else {
                    pixels[offset + 2] = 255
                }
                pixels[offset + 3] = 255
            }
        }
        let data = Data(pixels) as CFData
        guard let provider = CGDataProvider(data: data),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            throw TempoError.contextCreationFailed
        }
        return image
    }

    private static func makeSolidJPEG(index: Int, at url: URL) throws {
        guard let context = CGContext(
            data: nil,
            width: 320,
            height: 180,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { throw TempoError.contextCreationFailed }
        context.setFillColor(colors[index % colors.count])
        context.fill(CGRect(x: 0, y: 0, width: 320, height: 180))
        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(
                url as CFURL,
                UTType.jpeg.identifier as CFString,
                1,
                nil
              ) else {
            throw TempoError.imageWriteFailed
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw TempoError.imageWriteFailed
        }
    }
}
