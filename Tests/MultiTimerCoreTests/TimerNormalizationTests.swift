import XCTest
@testable import MultiTimerCore

final class TimerNormalizationTests: XCTestCase {

    // MARK: - TC-Norm 正規化

    // TC-Norm-01: 正常な 1 件 → そのまま
    func testNormalizeValidTimer() {
        let dict: [String: Any] = ["id": "abc-123", "title": "作業", "configuredMs": 1000]
        let result = TimerNormalization.normalizeTimer(dict)
        XCTAssertEqual(result?.id, "abc-123")
        XCTAssertEqual(result?.title, "作業")
        XCTAssertEqual(result?.configuredMs, 1000)
    }

    // TC-Norm-02: id が空 → 新規 UUID
    func testNormalizeEmptyId() {
        let dict: [String: Any] = ["id": "", "title": "test", "configuredMs": 1000]
        let result = TimerNormalization.normalizeTimer(dict)!
        XCTAssertFalse(result.id.isEmpty)
        XCTAssertNotNil(UUID(uuidString: result.id))
    }

    // TC-Norm-03: title が 60 文字 → 先頭 50 文字
    func testNormalizeLongTitle() {
        let longTitle = String(repeating: "あ", count: 60)
        let dict: [String: Any] = ["id": "id1", "title": longTitle, "configuredMs": 0]
        let result = TimerNormalization.normalizeTimer(dict)!
        XCTAssertEqual(result.title.count, 50)
        XCTAssertEqual(result.title, String(repeating: "あ", count: 50))
    }

    // TC-Norm-04: title が数値型 → 空文字
    func testNormalizeNumericTitle() {
        let dict: [String: Any] = ["id": "id1", "title": 42, "configuredMs": 0]
        let result = TimerNormalization.normalizeTimer(dict)!
        XCTAssertEqual(result.title, "")
    }

    // TC-Norm-05: configuredMs が負 → 0
    func testNormalizeNegativeMs() {
        let dict: [String: Any] = ["id": "id1", "title": "t", "configuredMs": -100]
        let result = TimerNormalization.normalizeTimer(dict)!
        XCTAssertEqual(result.configuredMs, 0)
    }

    // TC-Norm-06: configuredMs が最大超過 → 最大値にクランプ
    func testNormalizeOverMax() {
        let dict: [String: Any] = ["id": "id1", "title": "t", "configuredMs": 999_999_999]
        let result = TimerNormalization.normalizeTimer(dict)!
        XCTAssertEqual(result.configuredMs, Constants.maxConfiguredMs)
    }

    // TC-Norm-07: configuredMs が小数 → floor
    func testNormalizeDecimalMs() {
        let dict: [String: Any] = ["id": "id1", "title": "t", "configuredMs": 3.7]
        let result = TimerNormalization.normalizeTimer(dict)!
        XCTAssertEqual(result.configuredMs, 3)
    }

    // TC-Norm-08: configuredMs が NaN/Inf → 0
    func testNormalizeNaNMs() {
        let dictNaN: [String: Any] = ["id": "id1", "title": "t", "configuredMs": Double.nan]
        XCTAssertEqual(TimerNormalization.normalizeTimer(dictNaN)!.configuredMs, 0)

        let dictInf: [String: Any] = ["id": "id2", "title": "t", "configuredMs": Double.infinity]
        XCTAssertEqual(TimerNormalization.normalizeTimer(dictInf)!.configuredMs, 0)
    }

    // TC-Norm-09: オブジェクトでない要素 → nil
    func testNormalizeNonObject() {
        XCTAssertNil(TimerNormalization.normalizeTimer(42))
        XCTAssertNil(TimerNormalization.normalizeTimer("string"))
        XCTAssertNil(TimerNormalization.normalizeTimer(NSNull()))
    }

    // MARK: - TC-Norm パース・移行

    private func makeTimer(id: String = "id1", title: String = "t", ms: Int = 1000) -> [String: Any] {
        ["id": id, "title": title, "configuredMs": ms]
    }

    // TC-Norm-10: { timers: [有効 2 件] } → 2 件、移行なし
    func testParseTwoValid() {
        let json: [String: Any] = ["timers": [makeTimer(id: "a"), makeTimer(id: "b")]]
        let result = TimerNormalization.parseTimers(from: json)
        XCTAssertEqual(result.timers.count, 2)
        XCTAssertFalse(result.migrated)
    }

    // TC-Norm-11: [有効, 無効, 有効] → 無効除外 2 件
    func testParseExcludesInvalidElements() {
        let json: [String: Any] = ["timers": [makeTimer(id: "a"), NSNull(), makeTimer(id: "c")] as [Any]]
        let result = TimerNormalization.parseTimers(from: json)
        XCTAssertEqual(result.timers.count, 2)
    }

    // TC-Norm-12: 13 件 → 先頭 12 件・移行あり
    func testParseTruncatesTo12() {
        let timers = (1...13).map { makeTimer(id: "id\($0)") }
        let json: [String: Any] = ["timers": timers]
        let result = TimerNormalization.parseTimers(from: json)
        XCTAssertEqual(result.timers.count, 12)
        XCTAssertTrue(result.migrated)
        XCTAssertEqual(result.timers.first?.id, "id1")
    }

    // TC-Norm-13: id なし要素 → 採番・移行あり
    func testParseGeneratesIdWhenMissing() {
        let json: [String: Any] = ["timers": [["title": "no-id", "configuredMs": 500]]]
        let result = TimerNormalization.parseTimers(from: json)
        XCTAssertEqual(result.timers.count, 1)
        XCTAssertFalse(result.timers[0].id.isEmpty)
        XCTAssertTrue(result.migrated)
    }

    // TC-Norm-14: レガシー形式 → 1 件配列に移行・移行あり
    func testParseLegacyFormat() {
        let json: [String: Any] = ["title": "old-timer", "configuredMs": 2000]
        let result = TimerNormalization.parseTimers(from: json)
        XCTAssertEqual(result.timers.count, 1)
        XCTAssertEqual(result.timers[0].title, "old-timer")
        XCTAssertTrue(result.migrated)
    }

    // TC-Norm-15: 空 { timers: [] } → 0 件
    func testParseEmptyTimers() {
        let json: [String: Any] = ["timers": [] as [Any]]
        let result = TimerNormalization.parseTimers(from: json)
        XCTAssertEqual(result.timers.count, 0)
        XCTAssertFalse(result.migrated)
    }

    // MARK: - TC-Number 採番

    // TC-Number-01: タイトルなし → 1
    func testNextNumberEmpty() {
        XCTAssertEqual(TimerNormalization.nextNewTimerNumber(existingTitles: []), 1)
    }

    // TC-Number-02: 新規タイマー1, 新規タイマー2 → 3
    func testNextNumberSequential() {
        XCTAssertEqual(TimerNormalization.nextNewTimerNumber(existingTitles: ["新規タイマー1", "新規タイマー2"]), 3)
    }

    // TC-Number-03: 新規タイマー1, 新規タイマー5 → 6（最大+1）
    func testNextNumberMax() {
        XCTAssertEqual(TimerNormalization.nextNewTimerNumber(existingTitles: ["新規タイマー1", "新規タイマー5"]), 6)
    }

    // TC-Number-04: 作業, 新規タイマー2 → 3
    func testNextNumberMixed() {
        XCTAssertEqual(TimerNormalization.nextNewTimerNumber(existingTitles: ["作業", "新規タイマー2"]), 3)
    }

    // TC-Number-05: 新規タイマーA（数字でない）→ 1
    func testNextNumberNonDigitSuffix() {
        XCTAssertEqual(TimerNormalization.nextNewTimerNumber(existingTitles: ["新規タイマーA"]), 1)
    }
}

// MARK: - TC-Notify 通知タイトル

final class NotificationTitleTests: XCTestCase {
    // TC-Notify-01
    func testNonEmptyTitle() {
        XCTAssertEqual(TimerNormalization.notificationTitle(timerTitle: "作業"), "作業 終了")
    }

    // TC-Notify-02
    func testEmptyTitle() {
        XCTAssertEqual(TimerNormalization.notificationTitle(timerTitle: ""), "タイマー終了")
    }

    // TC-Notify-03
    func testWhitespaceOnlyTitle() {
        XCTAssertEqual(TimerNormalization.notificationTitle(timerTitle: " "), "タイマー終了")
    }

    // TC-Notify-04
    func testTrimmedTitle() {
        XCTAssertEqual(TimerNormalization.notificationTitle(timerTitle: " 作業 "), "作業 終了")
    }
}
