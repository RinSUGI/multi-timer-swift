import Foundation

public enum TimeConversion {
    public static func toComponents(ms: Int) -> (hours: Int, minutes: Int, seconds: Int) {
        let totalSeconds = max(0, Int(ceil(Double(ms) / 1000.0)))
        return (totalSeconds / 3600, (totalSeconds % 3600) / 60, totalSeconds % 60)
    }

    public static func toMilliseconds(hours: Int, minutes: Int, seconds: Int) -> Int {
        (hours * 3600 + minutes * 60 + seconds) * 1000
    }

    public static func format(_ value: Int) -> String {
        String(format: "%02d", value)
    }
}
