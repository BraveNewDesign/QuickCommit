import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var store: RepositoryStore
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Constants.displayName).font(.headline)
            if let error = store.generalError, !error.userMessage.isEmpty { Text(error.userMessage).font(.caption).foregroundStyle(.red).lineLimit(3) }
            if store.repositories.isEmpty {
                ContentUnavailableView("No Repositories", systemImage: "folder", description: Text("Add a Git repository to begin."))
            } else if store.repositories.filter({ store.settings.showCleanRepositories || store.contexts[$0.id]?.changedFileCount ?? 0 > 0 }).isEmpty {
                ContentUnavailableView("All repositories are clean", systemImage: "checkmark.circle", description: Text("Repositories with changes will appear here."))
            } else {
                ForEach(store.repositories.filter { store.settings.showCleanRepositories || store.contexts[$0.id]?.changedFileCount ?? 0 > 0 }) { repository in
                    RepositoryRow(repository: repository, context: store.contexts[repository.id], error: store.errors[repository.id], progress: store.commitProgress[repository.id], onCommit: { store.commit(repository) }, onRetry: { Task { await store.refresh(repository) } }, isGloballyBusy: store.isBusy)
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
        .frame(minWidth: 300, idealWidth: 360, maxWidth: 460)
        .onAppear { store.start() }
    }
}
