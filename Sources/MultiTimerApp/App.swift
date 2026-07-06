import SwiftUI
import AppKit
import MultiTimerCore
import MultiTimerStorage

@main
struct MultiTimerApp: App {
    @StateObject private var vm: TimerListViewModel

    init() {
        do {
            let store = try TimerStore.makeDefault()
            let chime = ChimePlayer()
            let notif = NotificationScheduler()
            chime.warmUp()
            notif.requestAuthorization()
            _vm = StateObject(wrappedValue: TimerListViewModel(
                store: store,
                chime: chime,
                notification: notif
            ))
        } catch {
            fatalError("TimerStore initialization failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(vm)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: Constants.windowInitialWidth, height: Constants.windowInitialHeight)
    }
}
