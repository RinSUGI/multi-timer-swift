import Foundation
import SwiftUI
import MultiTimerCore
import MultiTimerStorage

@MainActor
final class TimerListViewModel: ObservableObject {
    @Published private(set) var timers: [TimerModel] = []

    private let store: TimerStore
    private let chime: any ChimePlaying
    private let notif: any NotificationScheduling
    private var tickTimers: [String: Foundation.Timer] = [:]
    private var debounceWork: [String: DispatchWorkItem] = [:]

    init(store: TimerStore, chime: any ChimePlaying, notification: any NotificationScheduling) {
        self.store = store
        self.chime = chime
        self.notif = notification
    }

    // MARK: - Load

    func load() async {
        let stored = await store.load()
        var models = stored.map { makeModel($0) }
        if models.isEmpty {
            let m = makeEmptyModel()
            models = [m]
            Task { await self.persist(m) }
        }
        timers = models
    }

    // MARK: - CRUD

    func addTimer() {
        guard timers.count < Constants.maxTimers else { return }
        let n = TimerNormalization.nextNewTimerNumber(existingTitles: timers.map(\.title))
        let m = makeModel(StoredTimer(id: UUID().uuidString, title: "新規タイマー\(n)", configuredMs: 0))
        timers.append(m)
        Task { await persist(m) }
    }

    func deleteTimer(_ id: String) {
        cancelDebounce(id)
        stopTick(id)
        timers.removeAll { $0.id == id }
        Task { await store.delete(id: id) }
    }

    // MARK: - Actions

    func start(_ id: String) {
        guard let m = find(id) else { return }
        let hadEditing = m.editingSegment != nil
        m.start()
        if hadEditing, m.isRunning { Task { await persist(m) } }
        if m.isRunning { beginTick(m) }
        objectWillChange.send()
    }

    func stop(_ id: String) {
        guard let m = find(id) else { return }
        m.stop()
        stopTick(id)
        objectWillChange.send()
    }

    func reset(_ id: String) {
        guard let m = find(id) else { return }
        m.reset()
        stopTick(id)
        objectWillChange.send()
    }

    func clear(_ id: String) {
        guard let m = find(id) else { return }
        m.clear()
        stopTick(id)
        objectWillChange.send()
        Task { await persist(m) }
    }

    func updateTitle(_ id: String, title: String) {
        guard let m = find(id) else { return }
        m.title = title
        objectWillChange.send()
        scheduleDebounce(id) { [weak self] in
            guard let self else { return }
            Task { await self.persist(m) }
        }
    }

    // MARK: - Segment Editing

    func beginEditing(_ id: String, segment: Segment) {
        guard let m = find(id), !m.isRunning else { return }
        m.clearExpiredState()
        if let prev = m.editingSegment, prev.segment != segment {
            m.commitEditing(segment: prev.segment, input: prev.input)
            Task { await persist(m) }
        }
        let (h, min, s) = TimeConversion.toComponents(ms: m.remainingMs)
        let v: Int
        switch segment {
        case .hours:   v = h
        case .minutes: v = min
        case .seconds: v = s
        }
        m.editingSegment = TimerModel.EditingState(segment: segment, input: TimeConversion.format(v))
        objectWillChange.send()
    }

    func updateInput(_ id: String, input: String) {
        guard let m = find(id), var e = m.editingSegment else { return }
        e.input = input
        m.editingSegment = e
        // No publish — NSTextField owns its display while the user is typing
    }

    func commitEditing(_ id: String) {
        guard let m = find(id), let e = m.editingSegment else { return }
        m.commitEditing(segment: e.segment, input: e.input)
        objectWillChange.send()
        Task { await persist(m) }
    }

    func commitAndMove(_ id: String, to next: Segment) {
        guard let m = find(id), let e = m.editingSegment else { return }
        m.commitEditing(segment: e.segment, input: e.input)
        let (h, min, s) = TimeConversion.toComponents(ms: m.remainingMs)
        let v: Int
        switch next {
        case .hours:   v = h
        case .minutes: v = min
        case .seconds: v = s
        }
        m.editingSegment = TimerModel.EditingState(segment: next, input: TimeConversion.format(v))
        objectWillChange.send()
        Task { await persist(m) }
    }

    func cancelEditing(_ id: String) {
        guard let m = find(id) else { return }
        m.editingSegment = nil
        objectWillChange.send()
    }

    // MARK: - Tick

    private func beginTick(_ m: TimerModel) {
        let id = m.id
        stopTick(id)
        let t = Foundation.Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard let m = self.find(id) else { self.stopTick(id); return }
                m.tick()
                if !m.isRunning { self.stopTick(id) }
                self.objectWillChange.send()
            }
        }
        t.tolerance = 0.05
        RunLoop.main.add(t, forMode: .common)
        tickTimers[id] = t
    }

    private func stopTick(_ id: String) {
        tickTimers[id]?.invalidate()
        tickTimers[id] = nil
    }

    // MARK: - Persistence

    private func persist(_ m: TimerModel) async {
        await store.save(StoredTimer(id: m.id, title: m.title, configuredMs: m.configuredMs))
    }

    private func scheduleDebounce(_ id: String, work: @escaping @Sendable () -> Void) {
        debounceWork[id]?.cancel()
        let item = DispatchWorkItem { work() }
        debounceWork[id] = item
        DispatchQueue.main.asyncAfter(
            deadline: .now() + .milliseconds(Constants.titleDebounceMs),
            execute: item
        )
    }

    private func cancelDebounce(_ id: String) {
        debounceWork[id]?.cancel()
        debounceWork[id] = nil
    }

    // MARK: - Helpers

    private func find(_ id: String) -> TimerModel? { timers.first { $0.id == id } }

    private func makeModel(_ s: StoredTimer) -> TimerModel {
        let m = TimerModel(id: s.id, title: s.title, configuredMs: s.configuredMs)
        m.chime = chime
        m.notification = notif
        return m
    }

    private func makeEmptyModel() -> TimerModel {
        let m = TimerModel(id: UUID().uuidString, title: "", configuredMs: 0)
        m.chime = chime
        m.notification = notif
        return m
    }
}
