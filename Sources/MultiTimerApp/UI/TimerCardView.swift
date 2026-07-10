import SwiftUI
import MultiTimerCore

struct TimerCardView: View {
    @EnvironmentObject private var vm: TimerListViewModel
    @Environment(\.vmin) private var vmin
    @Environment(\.compactButtons) private var compactButtons
    let model: TimerModel

    var body: some View {
        let timeFontSize = ScaledSize.timeFont(vmin: vmin)
        let titleFontSize = ScaledSize.titleFont(vmin: vmin)
        let btnFontSize = ScaledSize.buttonFont(vmin: vmin)
        let padH = ScaledSize.cardPadH(vmin: vmin)
        let padV = ScaledSize.cardPadV(vmin: vmin)

        VStack(spacing: padV * 0.8) {
            titleRow(fontSize: titleFontSize, padH: padH)
            timeRow(fontSize: timeFontSize, padH: padH)
            buttonRow(fontSize: btnFontSize, padH: padH, padV: padV)
        }
        .padding(.horizontal, padH)
        .padding(.vertical, padV)
    }

    // MARK: - Title Row

    @ViewBuilder
    private func titleRow(fontSize: Double, padH: Double) -> some View {
        HStack(spacing: 0) {
            TextField("タイトル", text: titleBinding)
                .font(.system(size: fontSize, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .lineLimit(1)
                .frame(maxWidth: 240)

            Spacer(minLength: 0)

            Button(action: { vm.deleteTimer(model.id) }) {
                ZStack {
                    Circle()
                        .fill(Color(hex: Constants.Color.deleteButton))
                        .frame(width: fontSize * 1.4, height: fontSize * 1.4)
                    Text("×")
                        .font(.system(size: fontSize * 0.9, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Time Row

    @ViewBuilder
    private func timeRow(fontSize: Double, padH: Double) -> some View {
        let (h, m, s) = TimeConversion.toComponents(ms: model.remainingMs)
        let timeColor: Color = model.expiredAfterCountdown
            ? Color(hex: Constants.Color.expired)
            : .white
        let nsColor = model.expiredAfterCountdown
            ? NSColor(red: 1, green: 0.84, blue: 0.04, alpha: 1)
            : NSColor.white

        HStack(spacing: 0) {
            segmentView(
                segment: .hours,
                displayValue: TimeConversion.format(h),
                fontSize: fontSize,
                textColor: timeColor,
                nsColor: nsColor
            )
            separatorText(fontSize: fontSize, color: timeColor)
            segmentView(
                segment: .minutes,
                displayValue: TimeConversion.format(m),
                fontSize: fontSize,
                textColor: timeColor,
                nsColor: nsColor
            )
            separatorText(fontSize: fontSize, color: timeColor)
            segmentView(
                segment: .seconds,
                displayValue: TimeConversion.format(s),
                fontSize: fontSize,
                textColor: timeColor,
                nsColor: nsColor
            )
        }
        .allowsHitTesting(!model.isRunning)
    }

    @ViewBuilder
    private func separatorText(fontSize: Double, color: Color) -> some View {
        Text(":")
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .frame(width: fontSize * 0.4)
    }

    @ViewBuilder
    private func segmentView(
        segment: Segment,
        displayValue: String,
        fontSize: Double,
        textColor: Color,
        nsColor: NSColor
    ) -> some View {
        let isEditing = model.editingSegment?.segment == segment

        Group {
            if isEditing {
                SegmentTextField(
                    text: editingInputBinding,
                    fontSize: CGFloat(fontSize),
                    textColor: nsColor,
                    onCommit:       { vm.commitEditing(model.id) },
                    onCancel:       { vm.cancelEditing(model.id) },
                    onTabForward:   { vm.commitAndMove(model.id, to: nextSegment(from: segment, wrap: true)) },
                    onTabBackward:  { vm.commitAndMove(model.id, to: prevSegment(from: segment, wrap: true)) },
                    onArrowRight:   {
                        if let next = nextSegmentNoWrap(from: segment) {
                            vm.commitAndMove(model.id, to: next)
                        }
                    },
                    onArrowLeft: {
                        if let prev = prevSegmentNoWrap(from: segment) {
                            vm.commitAndMove(model.id, to: prev)
                        }
                    }
                )
                .frame(width: fontSize * 1.4, height: fontSize * 1.4)
            } else {
                Text(displayValue)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .frame(width: fontSize * 1.4)
                    .contentShape(Rectangle())
                    .onTapGesture { vm.beginEditing(model.id, segment: segment) }
            }
        }
    }

    // MARK: - Button Row

    @ViewBuilder
    private func buttonRow(fontSize: Double, padH: Double, padV: Double) -> some View {
        let bPH = ScaledSize.buttonPadH(vmin: vmin)
        let bPV = ScaledSize.buttonPadV(vmin: vmin)

        HStack(spacing: padH * 0.5) {
            timerButton("Start", icon: "play.fill",
                        color: Color(hex: Constants.Color.startButton),
                        enabled: model.isStartEnabled, fontSize: fontSize,
                        padH: bPH, padV: bPV) { vm.start(model.id) }
            timerButton("Stop", icon: "stop.fill",
                        color: Color(hex: Constants.Color.stopButton),
                        enabled: model.isStopEnabled,  fontSize: fontSize,
                        padH: bPH, padV: bPV) { vm.stop(model.id) }
            timerButton("Reset", icon: "arrow.counterclockwise",
                        color: Color(hex: Constants.Color.resetButton),
                        enabled: model.isResetEnabled, fontSize: fontSize,
                        padH: bPH, padV: bPV) { vm.reset(model.id) }
            timerButton("Clear", icon: "xmark",
                        color: Color(hex: Constants.Color.clearButton),
                        enabled: model.isClearEnabled, fontSize: fontSize,
                        padH: bPH, padV: bPV) { vm.clear(model.id) }
        }
    }

    @ViewBuilder
    private func timerButton(
        _ label: String,
        icon: String,
        color: Color,
        enabled: Bool,
        fontSize: Double,
        padH: Double,
        padV: Double,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Group {
                if compactButtons {
                    Image(systemName: icon)
                        .accessibilityLabel(label)
                } else {
                    Text(label)
                        .lineLimit(1)
                }
            }
            .font(.system(size: fontSize, weight: .medium, design: .rounded))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ActionButtonStyle(color: color, disabled: !enabled))
        .padding(.horizontal, padH)
        .padding(.vertical, padV)
        .disabled(!enabled)
    }

    // MARK: - Bindings

    private var titleBinding: Binding<String> {
        Binding(
            get: { model.title },
            set: { vm.updateTitle(model.id, title: $0) }
        )
    }

    private var editingInputBinding: Binding<String> {
        Binding(
            get: { model.editingSegment?.input ?? "" },
            set: { vm.updateInput(model.id, input: $0) }
        )
    }

    // MARK: - Segment Navigation

    private func nextSegment(from s: Segment, wrap: Bool) -> Segment {
        switch s {
        case .hours:   return .minutes
        case .minutes: return .seconds
        case .seconds: return wrap ? .hours : .seconds
        }
    }

    private func prevSegment(from s: Segment, wrap: Bool) -> Segment {
        switch s {
        case .hours:   return wrap ? .seconds : .hours
        case .minutes: return .hours
        case .seconds: return .minutes
        }
    }

    private func nextSegmentNoWrap(from s: Segment) -> Segment? {
        switch s {
        case .hours:   return .minutes
        case .minutes: return .seconds
        case .seconds: return nil
        }
    }

    private func prevSegmentNoWrap(from s: Segment) -> Segment? {
        switch s {
        case .hours:   return nil
        case .minutes: return .hours
        case .seconds: return .minutes
        }
    }
}
