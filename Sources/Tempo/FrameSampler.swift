import Foundation

struct FrameSampler {
    let maximumFrames: Int
    private(set) var interval: TimeInterval

    init(maximumFrames: Int = 1_080, initialInterval: TimeInterval = 2) {
        self.maximumFrames = maximumFrames
        self.interval = initialInterval
    }

    mutating func indicesToKeep(afterAppending frameCount: Int) -> [Int]? {
        guard frameCount > maximumFrames else { return nil }
        interval *= 2
        return stride(from: 0, to: frameCount, by: 2).map { $0 }
    }
}
