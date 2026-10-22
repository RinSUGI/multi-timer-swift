import SwiftUI
import AppKit
import MultiTimerCore

struct RootView: View {
    @EnvironmentObject private var vm: TimerListViewModel
    @Environment(\.vmin) private var vmin
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var cardFrames: [String: CGRect] = [:]
    @State private var drag: ReorderDrag? = nil

    var body: some View {
        GeometryReader { geo in
            let computedVmin = min(geo.size.width, geo.size.height) / 100.0
            let compactButtons = geo.size.width < ScaledSize.buttonLabelMinWidth
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(vm.timers, id: \.id) { model in
                            let isDragged = drag?.id == model.id
                            TimerCardView(
                                model: model,
                                onDragChanged: { dragChanged(model.id, travel: $0) },
                                onDragEnded: dragEnded
                            )
                            .background(GeometryReader { g in
                                Color.clear.preference(
                                    key: CardFramesKey.self,
                                    value: [model.id: g.frame(in: .named(Self.listSpace))]
                                )
                            })
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(isDragged ? 0.06 : 0))
                                    .shadow(color: .black.opacity(isDragged ? 0.5 : 0), radius: 8, y: 3)
                            )
                            .offset(y: drag?.offset(for: model.id) ?? 0)
                            .zIndex(isDragged ? 1 : 0)
                            .animation(isDragged ? nil : .easeInOut(duration: 0.18), value: drag?.offset(for: model.id))
                            .id(model.id)
                        }
                        addButton(vmin: computedVmin)
                        versionLabel(vmin: computedVmin)
                    }
                    .frame(maxWidth: .infinity)
                    .coordinateSpace(name: Self.listSpace)
                    .onPreferenceChange(CardFramesKey.self) { cardFrames = $0 }
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

    // MARK: - Reorder

    private static let listSpace = "timerList"

    private func dragChanged(_ id: String, travel: CGFloat) {
        if drag == nil {
            let ids = vm.timers.map(\.id)
            let frames = ids.compactMap { cardFrames[$0] }
            guard frames.count == ids.count, let index = ids.firstIndex(of: id) else { return }
            drag = ReorderDrag(id: id, ids: ids, frames: frames, index: index)
        }
        drag?.travel = travel
    }

    private func dragEnded() {
        guard let d = drag else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            vm.moveTimer(id: d.id, toIndex: d.insertion)
            drag = nil
        }
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

/// Transient drag state; card positions are snapshotted when the drag starts.
private struct ReorderDrag {
    let id: String
    let ids: [String]
    let frames: [CGRect]
    let index: Int
    var travel: CGFloat = 0

    /// Travel limited so the card stays between the first and last card (visual only).
    var clampedTravel: CGFloat {
        let f = frames[index]
        return min(max(travel, frames[0].minY - f.minY), frames[frames.count - 1].maxY - f.maxY)
    }

    var insertion: Int {
        TimerOrdering.insertionIndex(
            originalCenters: frames.map { Double($0.midY) },
            draggedIndex: index,
            currentCenter: Double(frames[index].midY + travel)
        )
    }

    func offset(for cardID: String) -> CGFloat {
        if cardID == id { return clampedTravel }
        guard let i = ids.firstIndex(of: cardID) else { return 0 }
        let k = insertion, h = frames[index].height
        if index < i && i <= k { return -h }
        if k <= i && i < index { return h }
        return 0
    }
}

private struct CardFramesKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}
