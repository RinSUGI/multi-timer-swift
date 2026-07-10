import SwiftUI

private struct VminKey: EnvironmentKey {
    // Default: 360px (initial window width) / 100
    static let defaultValue: Double = 3.6
}

extension EnvironmentValues {
    var vmin: Double {
        get { self[VminKey.self] }
        set { self[VminKey.self] = newValue }
    }
}

private struct CompactButtonsKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// When true, button rows show icons instead of text labels (narrow window).
    var compactButtons: Bool {
        get { self[CompactButtonsKey.self] }
        set { self[CompactButtonsKey.self] = newValue }
    }
}

extension Double {
    func clamped(min lo: Double, max hi: Double) -> Double {
        Swift.max(lo, Swift.min(hi, self))
    }
}

// CSS-equivalent clamp(min, factor * vmin, max) for each UI element.
enum ScaledSize {
    static func timeFont(vmin: Double) -> Double    { (vmin * 18.0).clamped(min: 28.8, max: 192.0) }
    static func buttonFont(vmin: Double) -> Double  { (vmin * 3.5).clamped(min: 8.8,  max: 17.6) }
    static func titleFont(vmin: Double) -> Double   { (vmin * 7.0).clamped(min: 8.8,  max: 17.6) }
    static func cardPadH(vmin: Double) -> Double    { (vmin * 3.0).clamped(min: 8.0,  max: 24.0) }
    static func cardPadV(vmin: Double) -> Double    { (vmin * 1.5).clamped(min: 4.0,  max: 12.0) }
    static func buttonPadH(vmin: Double) -> Double  { (vmin * 1.5).clamped(min: 4.0,  max: 12.0) }
    static func buttonPadV(vmin: Double) -> Double  { (vmin * 0.8).clamped(min: 2.0,  max: 8.0) }

    /// Below this window width, button labels are replaced by icons so the
    /// text cannot wrap and stretch the button height.
    static let buttonLabelMinWidth: Double = 300.0
}
