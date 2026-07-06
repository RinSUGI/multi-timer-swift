import XCTest
@testable import MultiTimerCore

final class TimeConversionTests: XCTestCase {
    // TC-Time-01
    func testZeroMs() {
        let (h, m, s) = TimeConversion.toComponents(ms: 0)
        XCTAssertEqual(h, 0); XCTAssertEqual(m, 0); XCTAssertEqual(s, 0)
    }

    // TC-Time-02
    func testExactSecond() {
        let (h, m, s) = TimeConversion.toComponents(ms: 1000)
        XCTAssertEqual(h, 0); XCTAssertEqual(m, 0); XCTAssertEqual(s, 1)
    }

    // TC-Time-03
    func testHalfSecondCeil() {
        let (h, m, s) = TimeConversion.toComponents(ms: 500)
        XCTAssertEqual(h, 0); XCTAssertEqual(m, 0); XCTAssertEqual(s, 1)
    }

    // TC-Time-04
    func testOneMs() {
        let (h, m, s) = TimeConversion.toComponents(ms: 1)
        XCTAssertEqual(h, 0); XCTAssertEqual(m, 0); XCTAssertEqual(s, 1)
    }

    // TC-Time-05
    func testOneHour() {
        let (h, m, s) = TimeConversion.toComponents(ms: 3_600_000)
        XCTAssertEqual(h, 1); XCTAssertEqual(m, 0); XCTAssertEqual(s, 0)
    }

    // TC-Time-06
    func testMaxConfiguredMs() {
        let (h, m, s) = TimeConversion.toComponents(ms: Constants.maxConfiguredMs)
        XCTAssertEqual(h, 99); XCTAssertEqual(m, 59); XCTAssertEqual(s, 59)
    }

    // TC-Time-07
    func testNegativeMs() {
        let (h, m, s) = TimeConversion.toComponents(ms: -100)
        XCTAssertEqual(h, 0); XCTAssertEqual(m, 0); XCTAssertEqual(s, 0)
    }

    // TC-Time-08
    func testToMilliseconds() {
        XCTAssertEqual(TimeConversion.toMilliseconds(hours: 1, minutes: 2, seconds: 3), 3_723_000)
    }

    // TC-Time-09
    func testFormatSingleDigit() {
        XCTAssertEqual(TimeConversion.format(5), "05")
    }

    // TC-Time-10
    func testFormatTwoDigits() {
        XCTAssertEqual(TimeConversion.format(59), "59")
    }

    // TC-Time-11 (second-boundary round trip)
    func testRoundTrip() {
        let ms = TimeConversion.toMilliseconds(hours: 1, minutes: 2, seconds: 3) // 3_723_000
        let (h, m, s) = TimeConversion.toComponents(ms: ms)
        XCTAssertEqual(TimeConversion.toMilliseconds(hours: h, minutes: m, seconds: s), ms)
    }
}
