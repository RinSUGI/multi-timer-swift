import XCTest
@testable import MultiTimerCore

final class TimerOrderingTests: XCTestCase {
    // MARK: - 挿入位置

    private let centers: [Double] = [50, 150, 250]

    private func index(_ dragged: Int, _ current: Double, _ c: [Double]? = nil) -> Int {
        TimerOrdering.insertionIndex(originalCenters: c ?? centers, draggedIndex: dragged, currentCenter: current)
    }

    func testTC_Order_01() { XCTAssertEqual(index(0, 40), 0) }
    func testTC_Order_02() { XCTAssertEqual(index(0, 160), 1) }
    func testTC_Order_03() { XCTAssertEqual(index(0, 260), 2) }
    func testTC_Order_04() { XCTAssertEqual(index(2, 140), 1) }
    func testTC_Order_05() { XCTAssertEqual(index(2, -100), 0) }
    func testTC_Order_06() { XCTAssertEqual(index(0, 150), 0) }
    func testTC_Order_07() { XCTAssertEqual(index(0, 500, [50]), 0) }

    // MARK: - id 列による並べ替え

    private func reorder(_ items: [String], _ ids: [String]) -> [String] {
        TimerOrdering.reordered(items, by: ids, id: { $0 })
    }

    func testTC_Order_08() { XCTAssertEqual(reorder(["A", "B", "C"], ["C", "A", "B"]), ["C", "A", "B"]) }
    func testTC_Order_09() { XCTAssertEqual(reorder(["A", "B", "C"], ["A", "B", "C"]), ["A", "B", "C"]) }
    func testTC_Order_10() { XCTAssertEqual(reorder(["A", "B", "C", "D"], ["C", "A"]), ["C", "A", "B", "D"]) }
    func testTC_Order_11() { XCTAssertEqual(reorder(["A", "B"], ["B", "X", "A"]), ["B", "A"]) }
    func testTC_Order_12() { XCTAssertEqual(reorder(["A", "B", "C"], ["C", "C", "A"]), ["C", "A", "B"]) }
    func testTC_Order_13() { XCTAssertEqual(reorder(["A", "B"], []), ["A", "B"]) }
    func testTC_Order_14() { XCTAssertEqual(reorder([], ["A"]), []) }

    // MARK: - 配列の移動

    func testTC_Order_15() { XCTAssertEqual(TimerOrdering.moved(["A", "B", "C"], from: 0, to: 2), ["B", "C", "A"]) }
    func testTC_Order_16() { XCTAssertEqual(TimerOrdering.moved(["A", "B", "C"], from: 2, to: 0), ["C", "A", "B"]) }
    func testTC_Order_17() { XCTAssertEqual(TimerOrdering.moved(["A", "B", "C"], from: 1, to: 1), ["A", "B", "C"]) }
}
