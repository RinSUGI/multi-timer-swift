import Foundation

public enum Segment: Equatable {
    case hours, minutes, seconds

    public var maxValue: Int {
        switch self {
        case .hours: return Constants.maxHours
        case .minutes: return Constants.maxMinutes
        case .seconds: return Constants.maxSeconds
        }
    }
}

public enum SegmentEditing {
    public static func clamp(input: String, segment: Segment) -> Int {
        let digits = input.filter { $0.isNumber }
        guard let value = Int(digits) else { return 0 }
        return min(max(value, 0), segment.maxValue)
    }

    public static func commitSegment(remainingMs: Int, segment: Segment, inputString: String) -> Int {
        let (h, m, s) = TimeConversion.toComponents(ms: remainingMs)
        let v = clamp(input: inputString, segment: segment)
        switch segment {
        case .hours:   return TimeConversion.toMilliseconds(hours: v, minutes: m, seconds: s)
        case .minutes: return TimeConversion.toMilliseconds(hours: h, minutes: v, seconds: s)
        case .seconds: return TimeConversion.toMilliseconds(hours: h, minutes: m, seconds: v)
        }
    }
}
