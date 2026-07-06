import XCTest
@testable import MultiTimerCore

// Test double for finish-handler verification
private final class DummyChime: ChimePlaying {
    var playCount = 0
    func playChime() { playCount += 1 }
}

private final class DummyNotification: NotificationScheduling {
    var callCount = 0
    var lastTitle = ""
    func scheduleFinish(title: String, body: String) {
        callCount += 1
        lastTitle = title
    }
}

final class TimerModelTests: XCTestCase {

    // MARK: - TC-State 遷移

    // TC-State-01: 残り 0 で Start → 変化なし
    func testStartIgnoredWhenRemainingZero() {
        let model = TimerModel(configuredMs: 0)
        model.start()
        XCTAssertFalse(model.isRunning)
    }

    // TC-State-02: 残り>0 で Start → 実行中・黄色 false
    func testStartSetsRunningAndClearsExpired() {
        let model = TimerModel(configuredMs: 1000)
        model.expiredAfterCountdown = true
        model.start()
        XCTAssertTrue(model.isRunning)
        XCTAssertFalse(model.expiredAfterCountdown)
    }

    // TC-State-03: 実行中 Stop → 停止・残り保持
    func testStopPreservesRemaining() {
        let clock = TestClock()
        let model = TimerModel(configuredMs: 1000, clock: clock)
        model.start()
        clock.advance(by: 0.3)
        model.tick()
        let remaining = model.remainingMs
        model.stop()
        XCTAssertFalse(model.isRunning)
        XCTAssertEqual(model.remainingMs, remaining)
    }

    // TC-State-04: 実行中 Reset → 停止・残り=設定・黄色 false のまま
    func testResetDuringRunning() {
        let model = TimerModel(configuredMs: 1000)
        model.start()
        XCTAssertFalse(model.expiredAfterCountdown)
        model.reset()
        XCTAssertFalse(model.isRunning)
        XCTAssertEqual(model.remainingMs, model.configuredMs)
        XCTAssertFalse(model.expiredAfterCountdown)
    }

    // TC-State-05: 停止・途中で Reset → 残り=設定
    func testResetFromStopped() {
        let clock = TestClock()
        let model = TimerModel(configuredMs: 1000, clock: clock)
        model.start()
        clock.advance(by: 0.3)
        model.tick()
        model.stop()
        XCTAssertNotEqual(model.remainingMs, model.configuredMs)
        model.reset()
        XCTAssertEqual(model.remainingMs, model.configuredMs)
    }

    // TC-State-06: Clear → 停止・残り=0・設定=0・黄色 false
    func testClear() {
        let model = TimerModel(configuredMs: 1000)
        model.start()
        model.expiredAfterCountdown = true
        model.clear()
        XCTAssertFalse(model.isRunning)
        XCTAssertEqual(model.remainingMs, 0)
        XCTAssertEqual(model.configuredMs, 0)
        XCTAssertFalse(model.expiredAfterCountdown)
    }

    // TC-State-07: tick で 0 到達 → 停止・残り=設定・黄色 true・終了処理 1 回
    func testTickReachesZero() {
        let clock = TestClock()
        let chime = DummyChime()
        let notification = DummyNotification()
        let model = TimerModel(configuredMs: 1000, clock: clock)
        model.chime = chime
        model.notification = notification
        model.start()
        clock.advance(by: 1.5)
        model.tick()
        XCTAssertFalse(model.isRunning)
        XCTAssertEqual(model.remainingMs, model.configuredMs)
        XCTAssertTrue(model.expiredAfterCountdown)
        XCTAssertEqual(chime.playCount, 1)
        XCTAssertEqual(notification.callCount, 1)
    }

    // TC-State-08: 黄色状態から Start → 黄色 false、再び 0 到達で true
    func testStartFromExpiredState() {
        let clock = TestClock()
        let chime = DummyChime()
        let model = TimerModel(configuredMs: 1000, clock: clock)
        model.chime = chime
        model.start()
        clock.advance(by: 1.5)
        model.tick()
        XCTAssertTrue(model.expiredAfterCountdown)

        // Start again from yellow state
        clock.advance(by: 0)
        model.start()
        XCTAssertFalse(model.expiredAfterCountdown)
        XCTAssertTrue(model.isRunning)

        clock.advance(by: 1.5)
        model.tick()
        XCTAssertTrue(model.expiredAfterCountdown)
        XCTAssertEqual(chime.playCount, 2)
    }

    // MARK: - TC-State tick（時刻注入）

    // TC-State-09: 300ms 経過 → 残り 700ms
    func testTick300ms() {
        let clock = TestClock()
        let model = TimerModel(configuredMs: 1000, clock: clock)
        model.start()
        clock.advance(by: 0.3)
        model.tick()
        XCTAssertEqual(model.remainingMs, 700)
    }

    // TC-State-10: 1500ms 経過 → 黄色 true・終了処理 1 回（auto-reset 後 remaining=configured）
    func testTick1500ms() {
        let clock = TestClock()
        let chime = DummyChime()
        let model = TimerModel(configuredMs: 1000, clock: clock)
        model.chime = chime
        model.start()
        clock.advance(by: 1.5)
        model.tick()
        XCTAssertTrue(model.expiredAfterCountdown)
        XCTAssertFalse(model.isRunning)
        XCTAssertEqual(chime.playCount, 1)
        XCTAssertEqual(model.remainingMs, model.configuredMs)
    }

    // TC-State-11: 200ms×複数回 → 合計経過分だけ減少
    func testTickMultipleSmallIntervals() {
        let clock = TestClock()
        let model = TimerModel(configuredMs: 1000, clock: clock)
        model.start()
        for _ in 0..<4 {
            clock.advance(by: 0.2)
            model.tick()
        }
        XCTAssertEqual(model.remainingMs, 200)
        XCTAssertTrue(model.isRunning)
    }

    // MARK: - TC-State ボタン活性

    // TC-State-12: 停止・残り 0
    func testButtonsWhenStoppedAndZero() {
        let model = TimerModel(configuredMs: 0)
        XCTAssertFalse(model.isStartEnabled)
        XCTAssertFalse(model.isStopEnabled)
        XCTAssertFalse(model.isResetEnabled)
        XCTAssertTrue(model.isClearEnabled)
    }

    // TC-State-13: 停止・残り>0・残り=設定
    func testButtonsWhenStoppedAndFull() {
        let model = TimerModel(configuredMs: 1000)
        XCTAssertTrue(model.isStartEnabled)
        XCTAssertFalse(model.isStopEnabled)
        XCTAssertFalse(model.isResetEnabled)
        XCTAssertTrue(model.isClearEnabled)
    }

    // TC-State-14: 停止・途中（残り≠設定、設定>0） → Reset=活性
    func testResetEnabledWhenStopped() {
        let clock = TestClock()
        let model = TimerModel(configuredMs: 1000, clock: clock)
        model.start()
        clock.advance(by: 0.3)
        model.tick()
        model.stop()
        XCTAssertTrue(model.isResetEnabled)
    }

    // TC-State-15: 実行中 → Start=非活性・Stop=活性・Reset=活性
    func testButtonsDuringRunning() {
        let model = TimerModel(configuredMs: 1000)
        model.start()
        XCTAssertFalse(model.isStartEnabled)
        XCTAssertTrue(model.isStopEnabled)
        XCTAssertTrue(model.isResetEnabled)
    }

    // TC-State-16: 自然終了直後（残り=設定、黄色） → Reset=非活性
    func testResetDisabledAfterNaturalExpiry() {
        let clock = TestClock()
        let model = TimerModel(configuredMs: 1000, clock: clock)
        model.start()
        clock.advance(by: 1.5)
        model.tick()
        XCTAssertTrue(model.expiredAfterCountdown)
        XCTAssertEqual(model.remainingMs, model.configuredMs)
        XCTAssertFalse(model.isResetEnabled)
    }
}
