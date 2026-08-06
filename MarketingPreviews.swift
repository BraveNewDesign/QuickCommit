import SwiftUI

private struct MarketingMenuBarPreview: View {
    let progress: CommitProgress?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Constants.displayName)
                .font(.headline)

            RepositoryRow(
                repository: RepositoryRecord(displayName: "QuickCommit"),
                context: CommitChangeContext(
                    changedFileCount: 3,
                    modifiedFileCount: 2,
                    untrackedFileCount: 1,
                    deletedFileCount: 0,
                    hasConflicts: false,
                    paths: ["README.md", "QuickCommit/Views/MenuBar/RepositoryRow.swift", "Docs/ReleaseNotes.md"]
                ),
                error: nil,
                progress: progress,
                onCommit: {},
                onRetry: {}
            )

            RepositoryRow(
                repository: RepositoryRecord(displayName: "DesignLab"),
                context: .empty,
                error: nil,
                progress: nil,
                onCommit: {},
                onRetry: {}
            )

            Divider()

            Button("Add Repository…") {}
            Button("Settings…") {}
            Button("Quit Quick Commit") {}
        }
        .padding()
        .frame(width: 390)
    }
}

#Preview("Commit Ready") {
    MarketingMenuBarPreview(progress: nil)
}

#Preview("Generating Message") {
    MarketingMenuBarPreview(progress: .generatingMessage)
}

#Preview("General Settings") {
    GeneralSettingsView(store: RepositoryStore())
        .frame(width: 560, height: 320)
}

#Preview("About") {
    AboutSettingsView()
        .frame(width: 560, height: 320)
}
