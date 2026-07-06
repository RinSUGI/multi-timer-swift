import Foundation

public protocol ChimePlaying {
    func playChime()
}

public protocol NotificationScheduling {
    func scheduleFinish(title: String, body: String)
}
