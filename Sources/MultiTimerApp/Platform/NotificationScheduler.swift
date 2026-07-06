import Foundation
import UserNotifications
import MultiTimerCore

public final class NotificationScheduler: NotificationScheduling {
    // Lazy so that UNUserNotificationCenter.current() is not called during swift run
    // (which has no app bundle). Notifications are silently suppressed in that case.
    private lazy var center: UNUserNotificationCenter? = {
        guard Bundle.main.bundleIdentifier != nil else { return nil }
        return UNUserNotificationCenter.current()
    }()

    public init() {}

    public func requestAuthorization() {
        center?.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    public func scheduleFinish(title: String, body: String) {
        guard let center else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        // Unique identifier per notification so concurrent finishes stack rather than collapse.
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request) { _ in }
    }
}
