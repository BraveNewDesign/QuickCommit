import SwiftUI

@main
struct QuickCommitApp: App {
    @StateObject private var store = RepositoryStore()
    var body: some Scene {
        MenuBarExtra("Quick Commits", systemImage: "arrow.trianglehead.branch") {
            MenuBarContentView(store: store)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(store: store)
        }
    }

}
