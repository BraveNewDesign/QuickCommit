import AppKit
import SwiftUI

@main
struct QuickCommitApp: App {
    @StateObject private var store: RepositoryStore

#if DEBUG
    private static var uiTestWindow: NSWindow?
#endif

    init() {
        let initialStore = RepositoryStore()
        _store = StateObject(wrappedValue: initialStore)

#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("QuickCommitUITestWindow") {
            Task { @MainActor in
                Self.presentUITestWindowIfNeeded(store: initialStore)
            }
        }
#endif
    }

    var body: some Scene {
        MenuBarExtra("Quick Commit", systemImage: "arrow.trianglehead.branch") {
            MenuBarContentView(store: store)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(store: store)
        }
    }

#if DEBUG
    @MainActor
    private static func presentUITestWindowIfNeeded(store: RepositoryStore) {
        guard uiTestWindow == nil else { return }

        let hostingView = NSHostingView(rootView: MenuBarContentView(store: store))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 460),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.identifier = NSUserInterfaceItemIdentifier("quickcommit-ui-test-window")
        window.title = "Quick Commit UI Test"
        window.isRestorable = false
        window.contentMinSize = NSSize(width: 320, height: 280)
        window.contentView = hostingView
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        uiTestWindow = window
    }
#endif

}
