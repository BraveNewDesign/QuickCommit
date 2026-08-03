import SwiftUI

struct RepositoryRow: View {
    let repository: RepositoryRecord
    let context: CommitChangeContext?
    let error: RepositoryError?
    let onCommit: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                RepositoryStatusIndicator(state: error == nil && (context?.changedFileCount ?? 0) == 0 ? .ready : .working)
                Text(repository.displayName).lineLimit(1)
                Spacer()
                if error == nil { Button("Checkpoint", action: onCommit).buttonStyle(.borderedProminent).controlSize(.small) }
                else { Button("Retry", action: onRetry).controlSize(.small) }
            }
            Text(error == nil ? ((context?.changedFileCount ?? 0) == 0 ? "Clean" : "\(context?.changedFileCount ?? 0) change(s) ready") : "Repository unavailable")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
