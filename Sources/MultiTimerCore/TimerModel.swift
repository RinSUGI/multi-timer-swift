import Foundation

public final class TimerModel {
    public let id: String
    public var title: String
    public var configuredMs: Int
    public var remainingMs: Int
    public var isRunning: Bool
    public var expiredAfterCountdown: Bool
    public var editingSegment: EditingState?

    private let clock: Clock
    private var lastTickTime: TimeInterval?
    public var chime: (any ChimePlaying)?
    public var notification: (any NotificationScheduling)?

    public struct EditingState: Equatable {
        public var segment: Segment
        public var input: String

        public init(segment: Segment, input: String) {
            self.segment = segment
            self.input = input
        }
    }

    public init(
        id: String = UUID().uuidString,
        title: String = "",
        configuredMs: Int = 0,
        clock: Clock = SystemClock()
    ) {
        self.id = id
        self.title = title
        self.configuredMs = configuredMs
        self.remainingMs = configuredMs
        self.isRunning = false
        self.expiredAfterCountdown = false
        self.editingSegment = nil
        self.clock = clock
    }

    public func start() {
        guard !isRunning && remainingMs > 0 else { return }
        if let editing = editingSegment {
            commitEditing(segment: editing.segment, input: editing.input)
            guard remainingMs > 0 else { return }
        }
        isRunning = true
        expiredAfterCountdown = false
        lastTickTime = clock.now
    }

    public func stop() {
        isRunning = false
        lastTickTime = nil
    }

    public func reset() {
        stop()
        editingSegment = nil
        remainingMs = configuredMs
        // expiredAfterCountdown is intentionally not changed
    }

    public func clear() {
        stop()
        remainingMs = 0
        configuredMs = 0
        editingSegment = nil
        expiredAfterCountdown = false
    }

    public func tick() {
        guard isRunning else { return }
        let currentTime = clock.now
        guard let lastTime = lastTickTime else {
            lastTickTime = currentTime
            return
        }
        let elapsedMs = lround((currentTime - lastTime) * 1000)
        lastTickTime = currentTime
        remainingMs = max(0, remainingMs - elapsedMs)

        if remainingMs == 0 {
            expiredAfterCountdown = true
            let notifyTitle = TimerNormalization.notificationTitle(timerTitle: title)
            chime?.playChime()
            notification?.scheduleFinish(title: notifyTitle, body: Constants.Notification.body)
            isRunning = false
            remainingMs = configuredMs
            lastTickTime = nil
        }
    }

    public func clearExpiredState() {
        expiredAfterCountdown = false
    }

    public func commitEditing(segment: Segment, input: String) {
        let newMs = SegmentEditing.commitSegment(remainingMs: remainingMs, segment: segment, inputString: input)
        remainingMs = newMs
        configuredMs = newMs
        expiredAfterCountdown = false
        editingSegment = nil
    }

    public var isStartEnabled: Bool { !isRunning && remainingMs > 0 }
    public var isStopEnabled: Bool { isRunning }
    public var isResetEnabled: Bool {
        isRunning || (configuredMs > 0 && remainingMs != configuredMs)
    }
    public var isClearEnabled: Bool { true }
}
