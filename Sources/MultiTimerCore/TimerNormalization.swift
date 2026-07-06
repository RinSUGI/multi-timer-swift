import Foundation

public struct StoredTimer: Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var configuredMs: Int

    public init(id: String, title: String, configuredMs: Int) {
        self.id = id
        self.title = title
        self.configuredMs = configuredMs
    }
}

public struct ParseResult: Equatable {
    public var timers: [StoredTimer]
    public var migrated: Bool

    public init(timers: [StoredTimer], migrated: Bool) {
        self.timers = timers
        self.migrated = migrated
    }
}

public enum TimerNormalization {
    public static func normalizeTimer(_ value: Any) -> StoredTimer? {
        guard let dict = value as? [String: Any] else { return nil }

        let id: String
        if let raw = dict["id"] as? String, !raw.isEmpty {
            id = raw
        } else {
            id = UUID().uuidString
        }

        let title: String
        if let raw = dict["title"] as? String {
            title = String(raw.prefix(Constants.maxTitleLength))
        } else {
            title = ""
        }

        let configuredMs: Int
        if let num = dict["configuredMs"] as? NSNumber {
            let d = num.doubleValue
            if d.isFinite {
                let floored = Int(floor(d))
                configuredMs = min(max(floored, 0), Constants.maxConfiguredMs)
            } else {
                configuredMs = 0
            }
        } else {
            configuredMs = 0
        }

        return StoredTimer(id: id, title: title, configuredMs: configuredMs)
    }

    public static func parseTimers(from jsonObject: Any) -> ParseResult {
        guard let dict = jsonObject as? [String: Any] else {
            return ParseResult(timers: [], migrated: false)
        }

        if let rawArray = dict["timers"] as? [Any] {
            var timers: [StoredTimer] = []
            var migrated = false
            for element in rawArray {
                guard let elemDict = element as? [String: Any] else { continue }
                let hasId = (elemDict["id"] as? String).map { !$0.isEmpty } ?? false
                if !hasId { migrated = true }
                if let t = normalizeTimer(element) { timers.append(t) }
            }
            if timers.count > Constants.maxTimers {
                migrated = true
                timers = Array(timers.prefix(Constants.maxTimers))
            }
            return ParseResult(timers: timers, migrated: migrated)
        } else {
            // Legacy format: { title, configuredMs }
            let timer = normalizeTimer(dict)
            return ParseResult(timers: timer.map { [$0] } ?? [], migrated: true)
        }
    }

    public static func nextNewTimerNumber(existingTitles: [String]) -> Int {
        let prefix = "新規タイマー"
        var maxN = 0
        for title in existingTitles {
            guard title.hasPrefix(prefix) else { continue }
            let suffix = String(title.dropFirst(prefix.count))
            guard !suffix.isEmpty, suffix.allSatisfy(\.isNumber), let n = Int(suffix) else { continue }
            maxN = max(maxN, n)
        }
        return maxN + 1
    }

    public static func notificationTitle(timerTitle: String) -> String {
        let trimmed = timerTitle.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "タイマー終了" : "\(trimmed) 終了"
    }
}
