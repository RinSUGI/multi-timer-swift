import AppKit
import SwiftUI

/// Reorder drag handle. AppKit-backed so the drag is not taken by window-background moving,
/// and so it can auto-scroll the enclosing NSScrollView. See docs/design-docs/20-spec/reordering.md.
struct DragHandle: NSViewRepresentable {
    /// Vertical travel in list-content points (positive = down). Includes auto-scroll.
    var onChanged: (CGFloat) -> Void
    var onEnded: () -> Void
    var onHoverChanged: (Bool) -> Void

    func makeNSView(context: Context) -> HandleView {
        let v = HandleView()
        v.handle = self
        return v
    }

    func updateNSView(_ nsView: HandleView, context: Context) {
        nsView.handle = self
    }

    final class HandleView: NSView {
        var handle: DragHandle?
        private var startY: CGFloat?
        private var lastWindowPoint: NSPoint = .zero
        private var dragging = false
        private var hovering = false
        private var scrollTimer: Foundation.Timer?

        private static let startThreshold: CGFloat = 3

        override var mouseDownCanMoveWindow: Bool { false }

        override func resetCursorRects() {
            addCursorRect(bounds, cursor: .openHand)
        }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            trackingAreas.forEach(removeTrackingArea)
            addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow], owner: self))
        }

        override func mouseEntered(with event: NSEvent) { setHover(true) }
        override func mouseExited(with event: NSEvent) { setHover(false) }

        private func setHover(_ on: Bool) {
            hovering = on
            handle?.onHoverChanged(on || dragging)
        }

        override func mouseDown(with event: NSEvent) {
            // Clicking the handle counts as clicking outside the segment / title field.
            window?.makeFirstResponder(nil)
            lastWindowPoint = event.locationInWindow
            startY = contentY(lastWindowPoint)
        }

        override func mouseDragged(with event: NSEvent) {
            lastWindowPoint = event.locationInWindow
            guard let dy = travel() else { return }
            if !dragging {
                guard abs(dy) >= Self.startThreshold else { return }
                dragging = true
                NSCursor.closedHand.push()
                startAutoScroll()
            }
            handle?.onChanged(dy)
        }

        override func mouseUp(with event: NSEvent) {
            startY = nil
            guard dragging else { return }
            dragging = false
            scrollTimer?.invalidate()
            scrollTimer = nil
            NSCursor.pop()
            handle?.onEnded()
            setHover(hovering)
        }

        // MARK: - Coordinates

        /// Y in the scroll view's document (list content) space, flipped so that down is positive.
        private func contentY(_ windowPoint: NSPoint) -> CGFloat {
            guard let doc = enclosingScrollView?.documentView else {
                return -windowPoint.y
            }
            let p = doc.convert(windowPoint, from: nil)
            return doc.isFlipped ? p.y : -p.y
        }

        private func travel() -> CGFloat? {
            guard let startY else { return nil }
            return contentY(lastWindowPoint) - startY
        }

        // MARK: - Auto Scroll

        private func startAutoScroll() {
            let t = Foundation.Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.autoScrollStep() }
            }
            RunLoop.main.add(t, forMode: .common)
            scrollTimer = t
        }

        private func autoScrollStep() {
            // SwiftUI's NSScrollView is flipped (y grows downward).
            guard let sv = enclosingScrollView, let doc = sv.documentView, sv.contentView.isFlipped else { return }
            let clip = sv.contentView
            let visible = clip.bounds
            let zone = (visible.height * 0.15).clamped(min: 16, max: 48)
            let fromTop = clip.convert(lastWindowPoint, from: nil).y - visible.minY
            let fromBottom = visible.height - fromTop
            let maxSpeed: CGFloat = 16  // pt per frame at the very edge

            let step: CGFloat
            if fromTop < zone {
                step = -maxSpeed * min(1, (zone - fromTop) / zone)
            } else if fromBottom < zone {
                step = maxSpeed * min(1, (zone - fromBottom) / zone)
            } else {
                return
            }

            // The transparent title bar adds a top content inset, so the top is at -inset, not 0.
            let minY = -sv.contentInsets.top
            let maxY = max(minY, doc.frame.height - visible.height + sv.contentInsets.bottom)
            let next = (visible.minY + step).clamped(min: minY, max: maxY)
            guard next != visible.minY else { return }
            clip.scroll(to: NSPoint(x: visible.minX, y: next))
            sv.reflectScrolledClipView(clip)
            if let dy = travel() { handle?.onChanged(dy) }
        }
    }
}

private extension CGFloat {
    func clamped(min lo: CGFloat, max hi: CGFloat) -> CGFloat { Swift.max(lo, Swift.min(hi, self)) }
}
