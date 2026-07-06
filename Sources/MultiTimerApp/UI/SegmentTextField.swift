import AppKit
import SwiftUI
import MultiTimerCore

/// NSTextField wrapper for HH:MM:SS segment editing.
/// Handles digit-only filtering, 2-char limit, and all key navigation.
struct SegmentTextField: NSViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat
    let textColor: NSColor
    var onCommit: () -> Void
    var onCancel: () -> Void
    var onTabForward: () -> Void
    var onTabBackward: () -> Void
    var onArrowRight: () -> Void
    var onArrowLeft: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.delegate = context.coordinator
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.alignment = .center
        field.stringValue = text
        applyStyle(to: field)
        // Select all text once the view is in the window
        DispatchQueue.main.async {
            field.window?.makeFirstResponder(field)
            (field.currentEditor() as? NSTextView)?.selectAll(nil)
        }
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        applyStyle(to: nsView)
        // Don't overwrite user input while the field is focused
        if nsView.window?.firstResponder !== nsView.currentEditor() {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    private func applyStyle(to field: NSTextField) {
        field.font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        field.textColor = textColor
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: SegmentTextField
        private var suppressEndEditing = false

        init(_ parent: SegmentTextField) { self.parent = parent }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            let filtered = String(field.stringValue.filter(\.isNumber).prefix(2))
            if field.stringValue != filtered {
                let editor = field.currentEditor() as? NSTextView
                field.stringValue = filtered
                // Restore cursor to end after programmatic replacement
                editor?.setSelectedRange(NSRange(location: filtered.count, length: 0))
            }
            parent.text = filtered
        }

        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            suppressEndEditing = true
            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)):
                parent.onCommit()
            case #selector(NSResponder.cancelOperation(_:)):
                parent.onCancel()
            case #selector(NSResponder.insertTab(_:)):
                parent.onTabForward()
            case #selector(NSResponder.insertBacktab(_:)):
                parent.onTabBackward()
            case #selector(NSResponder.moveRight(_:)):
                parent.onArrowRight()
            case #selector(NSResponder.moveLeft(_:)):
                parent.onArrowLeft()
            default:
                suppressEndEditing = false
                return false
            }
            return true
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            if suppressEndEditing {
                suppressEndEditing = false
                return
            }
            parent.onCommit()
        }
    }
}
