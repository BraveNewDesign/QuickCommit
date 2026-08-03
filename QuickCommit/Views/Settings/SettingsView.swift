import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: RepositoryStore
    var body: some View {
        TabView {
            GeneralSettingsView(store: store).tabItem { Label("General", systemImage: "gear") }
            RepositorySettingsView(store: store).tabItem { Label("Repositories", systemImage: "folder") }
            AboutSettingsView().tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 560, height: 320)
    }
}
