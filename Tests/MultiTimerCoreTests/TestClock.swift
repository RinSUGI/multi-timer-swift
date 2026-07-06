import Foundation
import MultiTimerCore

final class TestClock: Clock {
    var currentTime: TimeInterval

    init(initial: TimeInterval = 0) {
        self.currentTime = initial
    }

    var now: TimeInterval { currentTime }

    func advance(by seconds: TimeInterval) {
        currentTime += seconds
    }
}
