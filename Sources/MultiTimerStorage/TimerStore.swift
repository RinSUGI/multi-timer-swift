import Foundation
import MultiTimerCore

public actor TimerStore {
    private let directoryURL: URL
    private var fileURL: URL { directoryURL.appendingPathComponent("timer.json") }

    public init(directory: URL) throws {
        self.directoryURL = directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public static func makeDefault() throws -> TimerStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return try TimerStore(directory: base.appendingPathComponent("multi-timer"))
    }

    public func load() -> [StoredTimer] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            print("[TimerStore] read error: \(error)")
            return []
        }
        let jsonObject: Any
        do {
            jsonObject = try JSONSerialization.jsonObject(with: data)
        } catch {
            print("[TimerStore] JSON parse failed, evacuating: \(error)")
            evacuateCorruptFile()
            return []
        }
        let result = TimerNormalization.parseTimers(from: jsonObject)
        if result.migrated {
            writeTimers(result.timers)
        }
        return result.timers
    }

    public func save(_ timer: StoredTimer) {
        let normalized = applyNormalization(timer)
        var timers = load()
        if let idx = timers.firstIndex(where: { $0.id == normalized.id }) {
            timers[idx] = normalized
        } else {
            timers.append(normalized)
        }
        if timers.count > Constants.maxTimers {
            timers = Array(timers.prefix(Constants.maxTimers))
        }
        writeTimers(timers)
    }

    public func delete(id: String) {
        let timers = load()
        let filtered = timers.filter { $0.id != id }
        if filtered.count != timers.count {
            writeTimers(filtered)
        }
    }

    private func applyNormalization(_ timer: StoredTimer) -> StoredTimer {
        let id = timer.id.isEmpty ? UUID().uuidString : timer.id
        let title = String(timer.title.prefix(Constants.maxTitleLength))
        let ms = min(max(timer.configuredMs, 0), Constants.maxConfiguredMs)
        return StoredTimer(id: id, title: title, configuredMs: ms)
    }

    private func writeTimers(_ timers: [StoredTimer]) {
        struct Payload: Encodable {
            let timers: [StoredTimer]
        }
        do {
            let data = try JSONEncoder().encode(Payload(timers: timers))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[TimerStore] write error: \(error)")
        }
    }

    private func evacuateCorruptFile() {
        let ts = Int(Date().timeIntervalSince1970)
        let dst = directoryURL.appendingPathComponent("timer.corrupt-\(ts).json")
        do {
            try FileManager.default.moveItem(at: fileURL, to: dst)
        } catch {
            print("[TimerStore] evacuate error: \(error)")
        }
    }
}
