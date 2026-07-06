import Foundation

public protocol Clock {
    var now: TimeInterval { get }
}

public struct SystemClock: Clock {
    public init() {}
    public var now: TimeInterval { Date().timeIntervalSinceReferenceDate }
}
