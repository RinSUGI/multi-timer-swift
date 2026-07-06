import Foundation
import UserNotifications
import MultiTimerCore

public final class NotificationScheduler: NotificationScheduling {
    private let center = UNUserNotificationCenter.current()

    public init() {}

    // Call at startup to prompt the user for notification permission.
    // The app continues normally if permission is denied — only the notification is suppressed.
    public func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    public func scheduleFinish(title: String, body: String) {
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
