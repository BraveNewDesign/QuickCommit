import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var store: RepositoryStore
    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $store.settings.launchAtLogin)
                Toggle("Use Apple Intelligence", isOn: $store.settings.useAppleIntelligence)
                Toggle("Show clean repositories", isOn: $store.settings.showCleanRepositories)
            }
            Section("Commit Identity") {
                Text("Optional override; the repository Git identity is used when both fields are blank.").font(.caption).foregroundStyle(.secondary)
                TextField("Name", text: Binding(get: { store.settings.commitIdentity?.name ?? "" }, set: { store.settings.commitIdentity = CommitIdentity(name: $0, email: store.settings.commitIdentity?.email ?? "") }))
                TextField("Email", text: Binding(get: { store.settings.commitIdentity?.email ?? "" }, set: { store.settings.commitIdentity = CommitIdentity(name: store.settings.commitIdentity?.name ?? "", email: $0) }))
                if let error = store.launchAtLoginError { Text(error.userMessage).font(.caption).foregroundStyle(.red) }
            }
        }.padding()
        .onChange(of: store.settings) { _, _ in store.persistSettings() }
    }
}
