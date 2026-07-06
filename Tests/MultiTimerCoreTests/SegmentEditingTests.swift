import XCTest
@testable import MultiTimerCore

final class SegmentEditingTests: XCTestCase {
    // MARK: - TC-Clamp

    // TC-Clamp-01
    func testClampHoursNormal() {
        XCTAssertEqual(SegmentEditing.clamp(input: "5", segment: .hours), 5)
    }

    // TC-Clamp-02
    func testClampHoursMax() {
        XCTAssertEqual(SegmentEditing.clamp(input: "99", segment: .hours), 99)
    }

    // TC-Clamp-03
    func testClampHoursOverLimit() {
        XCTAssertEqual(SegmentEditing.clamp(input: "100", segment: .hours), 99)
    }

    // TC-Clamp-04
    func testClampMinutesOverLimit() {
        XCTAssertEqual(SegmentEditing.clamp(input: "60", segment: .minutes), 59)
    }

    // TC-Clamp-05
    func testClampSecondsOverLimit() {
        XCTAssertEqual(SegmentEditing.clamp(input: "60", segment: .seconds), 59)
    }

    // TC-Clamp-06
    func testClampMinutesEmpty() {
        XCTAssertEqual(SegmentEditing.clamp(input: "", segment: .minutes), 0)
    }

    // TC-Clamp-07
    func testClampNonDigitRemoval() {
        XCTAssertEqual(SegmentEditing.clamp(input: "1a2", segment: .minutes), 12)
    }

    // TC-Clamp-08
    func testClampAllNonDigit() {
        XCTAssertEqual(SegmentEditing.clamp(input: "abc", segment: .seconds), 0)
    }

    // TC-Clamp-09
    func testClampMinusSign() {
        XCTAssertEqual(SegmentEditing.clamp(input: "-5", segment: .hours), 5)
    }

    // MARK: - TC-Edit

    // TC-Edit-01
    func testCommitMinutesToEmpty() {
        let ms = SegmentEditing.commitSegment(remainingMs: 0, segment: .minutes, inputString: "5")
        XCTAssertEqual(ms, 5 * 60 * 1000)
    }

    // TC-Edit-02
    func testCommitHoursPreservesOtherSegments() {
        let remaining = TimeConversion.toMilliseconds(hours: 0, minutes: 5, seconds: 0)
        let ms = SegmentEditing.commitSegment(remainingMs: remaining, segment: .hours, inputString: "1")
        XCTAssertEqual(ms, TimeConversion.toMilliseconds(hours: 1, minutes: 5, seconds: 0))
    }

    // TC-Edit-03 (expiredAfterCountdown cleared by commitEditing on TimerModel)
    func testCommitClearsExpiredFlag() {
        let clock = TestClock()
        let model = TimerModel(configuredMs: 1000, clock: clock)
        model.expiredAfterCountdown = true
        model.editingSegment = TimerModel.EditingState(segment: .minutes, input: "1")
        model.commitEditing(segment: .minutes, input: "1")
        XCTAssertFalse(model.expiredAfterCountdown)
    }

    // TC-Edit-04
    func testCommitClampsOverLimit() {
        let (_, m, _) = TimeConversion.toComponents(
            ms: SegmentEditing.commitSegment(remainingMs: 0, segment: .minutes, inputString: "70")
        )
        XCTAssertEqual(m, 59)
    }
}
