import AVFoundation
import CoreGraphics
import CoreVideo
import Foundation
import ImageIO

actor VideoExporter {
    static let framesPerSecond: Int32 = 30

    func export(
        frames: [URL],
        to outputURL: URL,
        quality: OutputQuality,
        onProgress: @escaping @Sendable (Double) async -> Void
    ) async throws {
        guard let firstURL = frames.first,
              let firstImage = Self.loadImage(firstURL) else {
            throw TempoError.noFrames
        }

        try? FileManager.default.removeItem(at: outputURL)
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: firstImage.width,
            AVVideoHeightKey: firstImage.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: quality.bitrate,
                AVVideoMaxKeyFrameIntervalKey: 60
            ]
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: firstImage.width,
                kCVPixelBufferHeightKey as String: firstImage.height,
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
            ]
        )

        guard writer.canAdd(input) else { throw TempoError.videoSetupFailed("formato não suportado") }
        writer.add(input)
        guard writer.startWriting() else {
            throw TempoError.videoSetupFailed(writer.error?.localizedDescription ?? "falha ao iniciar")
        }
        writer.startSession(atSourceTime: .zero)

        for (index, frameURL) in frames.enumerated() {
            while !input.isReadyForMoreMediaData {
                if writer.status == .failed {
                    throw TempoError.videoSetupFailed(writer.error?.localizedDescription ?? "falha na codificação")
                }
                try await Task.sleep(nanoseconds: 5_000_000)
            }

            guard let image = Self.loadImage(frameURL),
                  let pool = adaptor.pixelBufferPool else {
                throw TempoError.videoSetupFailed("quadro temporário inválido")
            }
            let buffer = try Self.makePixelBuffer(from: image, pool: pool)
            let presentationTime = CMTime(value: Int64(index), timescale: Self.framesPerSecond)
            guard adaptor.append(buffer, withPresentationTime: presentationTime) else {
                throw TempoError.videoSetupFailed(writer.error?.localizedDescription ?? "falha ao gravar quadro")
            }

            if index.isMultiple(of: 12) || index == frames.count - 1 {
                await onProgress(Double(index + 1) / Double(frames.count))
            }
        }

        input.markAsFinished()
        await writer.finishWriting()
        guard writer.status == .completed else {
            throw TempoError.videoSetupFailed(writer.error?.localizedDescription ?? "exportação incompleta")
        }
    }

    private static func loadImage(_ url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private static func makePixelBuffer(from image: CGImage, pool: CVPixelBufferPool) throws -> CVPixelBuffer {
        var optionalBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &optionalBuffer)
        guard status == kCVReturnSuccess, let buffer = optionalBuffer else {
            throw TempoError.videoSetupFailed("memória de vídeo indisponível")
        }

        try draw(image, into: buffer)
        return buffer
    }

    static func draw(_ image: CGImage, into buffer: CVPixelBuffer) throws {
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            throw TempoError.videoSetupFailed("buffer de vídeo inválido")
        }
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            throw TempoError.contextCreationFailed
        }
        // CGImage and CVPixelBuffer already agree on row order here. Applying
        // another vertical transform would turn every exported frame upside down.
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
}
