import XCTest
@testable import Tempo

final class FrameSamplerTests: XCTestCase {
    func testKeepsFramesUntilLimitIsExceeded() {
        var sampler = FrameSampler(maximumFrames: 4, initialInterval: 2)
        XCTAssertNil(sampler.indicesToKeep(afterAppending: 4))
        XCTAssertEqual(sampler.interval, 2)
    }

    func testCompactionKeepsUniformEvenIndicesAndDoublesInterval() {
        var sampler = FrameSampler(maximumFrames: 4, initialInterval: 2)
        XCTAssertEqual(sampler.indicesToKeep(afterAppending: 5), [0, 2, 4])
        XCTAssertEqual(sampler.interval, 4)
    }

    func testRepeatedCompactionKeepsDoublingInterval() {
        var sampler = FrameSampler(maximumFrames: 4, initialInterval: 2)
        _ = sampler.indicesToKeep(afterAppending: 5)
        _ = sampler.indicesToKeep(afterAppending: 5)
        XCTAssertEqual(sampler.interval, 8)
    }
}
