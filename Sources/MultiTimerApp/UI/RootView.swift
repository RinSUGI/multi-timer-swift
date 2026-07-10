import SwiftUI
import AppKit
import MultiTimerCore

struct RootView: View {
    @EnvironmentObject private var vm: TimerListViewModel
    @Environment(\.vmin) private var vmin
    @State private var scrollProxy: ScrollViewProxy? = nil

    var body: some View {
        GeometryReader { geo in
            let computedVmin = min(geo.size.width, geo.size.height) / 100.0
            let compactButtons = geo.size.width < ScaledSize.buttonLabelMinWidth
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(vm.timers, id: \.id) { model in
                            TimerCardView(model: model)
                                .id(model.id)
                        }
                        addButton(vmin: computedVmin)
                        versionLabel(vmin: computedVmin)
                    }
                    .frame(maxWidth: .infinity)
                }
                .onAppear {
                    scrollProxy = proxy
                    configureWindow()
                }
            }
            .environment(\.vmin, computedVmin)
            .environment(\.compactButtons, compactButtons)
        }
        .background(Color(hex: Constants.windowBackgroundHex))
        .preferredColorScheme(.dark)
        .task { await vm.load() }
    }

    // MARK: - Add Button

    @ViewBuilder
    private func addButton(vmin: Double) -> some View {
        let disabled = vm.timers.count >= Constants.maxTimers
        let titleFontSize = ScaledSize.titleFont(vmin: vmin)
        let padV = ScaledSize.cardPadV(vmin: vmin)

        Button(action: {
            guard !disabled else { return }
            vm.addTimer()
            if let last = vm.timers.last {
                withAnimation { scrollProxy?.scrollTo(last.id, anchor: .bottom) }
            }
        }) {
            VStack(spacing: padV * 0.6) {
                Divider()
                    .background(Color.white.opacity(0.2))
                Text("+")
                    .font(.system(size: titleFontSize * 1.4, weight: .light, design: .rounded))
                    .foregroundColor(disabled ? Color.white.opacity(0.25) : Color.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, padV)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .allowsHitTesting(!disabled)
    }

    // MARK: - Version Label

    @ViewBuilder
    private func versionLabel(vmin: Double) -> some View {
        Text("v\(Constants.appVersion)")
            .font(.system(size: ScaledSize.buttonFont(vmin: vmin) * 0.85, design: .rounded))
            .foregroundColor(.white.opacity(0.3))
            .padding(.bottom, ScaledSize.cardPadV(vmin: vmin))
    }

    // MARK: - Window Configuration

    private func configureWindow() {
        DispatchQueue.main.async {
            guard let window = NSApplication.shared.windows.first else { return }
            WindowConfigurator.configure(window)
        }
    }
}
