import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var store: RepositoryStore
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Constants.displayName).font(.headline)
            if store.repositories.isEmpty {
                ContentUnavailableView("No Repositories", systemImage: "folder", description: Text("Add a Git repository to begin."))
            } else {
                ForEach(store.repositories.filter { store.settings.showCleanRepositories || store.contexts[$0.id]?.changedFileCount ?? 0 > 0 }) { repository in
                    RepositoryRow(repository: repository, context: store.contexts[repository.id], error: store.errors[repository.id], onCommit: { store.commit(repository) }, onRetry: { Task { await store.refresh(repository) } })
                }
            }
            Divider()
            Button("Add Repository…") { store.addRepository() }
            SettingsLink {
                Text("Settings…")
            }
            Button("Quit Quick Commit") { NSApp.terminate(nil) }
        }
        .padding()
        .frame(width: 260)
        .onAppear { store.start() }
    }
}
