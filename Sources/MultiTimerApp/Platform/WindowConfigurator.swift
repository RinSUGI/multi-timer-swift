import AppKit
import MultiTimerCore

public enum WindowConfigurator {
    // Apply all window settings that require AppKit and cannot be done from SwiftUI alone.
    // Call this after the NSWindow is created, before it becomes visible.
    public static func configure(_ window: NSWindow) {
        // Hide title bar text/icon while keeping traffic-light buttons
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)

        window.setContentSize(NSSize(
            width: Constants.windowInitialWidth,
            height: Constants.windowInitialHeight
        ))
        window.minSize = NSSize(
            width: Constants.windowMinWidth,
            height: Constants.windowMinHeight
        )

        window.backgroundColor = NSColor(hexString: Constants.windowBackgroundHex)

        // Allow dragging the window from the background area.
        // Interactive views (buttons, text fields) override this naturally.
        window.isMovableByWindowBackground = true
    }
}

private extension NSColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
