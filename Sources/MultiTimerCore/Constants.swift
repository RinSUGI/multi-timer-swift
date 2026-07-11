import Foundation

public enum Constants {
    // MARK: - Timer Limits
    public static let maxTimers = 12
    public static let maxTitleLength = 50
    /// 99:59:59 in milliseconds
    public static let maxConfiguredMs = (99 * 3600 + 59 * 60 + 59) * 1000  // 359_999_000

    // MARK: - Segment Limits
    public static let maxHours = 99
    public static let maxMinutes = 59
    public static let maxSeconds = 59

    // MARK: - Debounce
    public static let titleDebounceMs = 300

    // MARK: - Window
    public static let windowInitialWidth: Double = 360
    public static let windowInitialHeight: Double = 480
    public static let windowMinWidth: Double = 120
    public static let windowMinHeight: Double = 100
    public static let windowTopMargin: Double = 28
    public static let windowBackgroundHex = "#1c1c1e"

    // MARK: - Colors (hex strings; UI layer converts to SwiftUI Color)
    public enum Color {
        public static let text = "#ffffff"
        public static let expired = "#ffd60a"
        public static let startButton = "#34c759"
        public static let stopButton = "#ff3b30"
        public static let resetButton = "#007aff"
        public static let clearButton = "#8e8e93"
        public static let deleteButton = "#ff3b30"
    }

    // MARK: - Chime
    public enum Chime {
        public enum E {
            public static let chord: [Double] = [261.63, 329.63, 392.00]
            public static let melody: Double = 659.25
            public static let duration: Double = 0.45
        }
        public enum D {
            public static let chord: [Double] = [233.08, 293.66, 349.23]
            public static let melody: Double = 587.33
            public static let duration: Double = 0.90
        }
        public static let fundamentalAmplitude: Double = 0.07
        public static let secondHarmonicAmplitude: Double = 0.02
        public static let thirdHarmonicAmplitude: Double = 0.007
    }

    // MARK: - Notification
    public enum Notification {
        public static let body = "設定した時間が経過しました"
    }

    // MARK: - Version
    public static let appVersion = "1.0.6"
}
