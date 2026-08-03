import SwiftUI

struct RepositorySettingsView: View {
    @ObservedObject var store: RepositoryStore
    var body: some View {
        VStack(alignment: .leading) {
            List { ForEach(store.repositories) { repository in
                HStack { Text(repository.displayName); Spacer(); Button("Remove") { store.remove(repository) } }
            }}
            Button("Add Repository…") { store.addRepository() }.padding()
        }
    }
}
