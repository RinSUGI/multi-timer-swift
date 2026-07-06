import SwiftUI
import AppKit
import MultiTimerCore
import MultiTimerStorage

@main
struct MultiTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
        .commands {
            // Remove "New Window" — this is a single-window app
            CommandGroup(replacing: .newItem) {}
        }
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    // Keep the app resident in the Dock when the window is closed (OQ-11)
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // Reopen the window when the user clicks the Dock icon (OQ-11)
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            sender.windows.first?.makeKeyAndOrderFront(nil)
        }
        return true
    }
}
