import SwiftUI

struct RepositoryRow: View {
    let repository: RepositoryRecord
    let context: CommitChangeContext?
    let error: RepositoryError?
    let progress: CommitProgress?
    let onCommit: () -> Void
    let onRetry: () -> Void

    private var hasChanges: Bool {
        (context?.changedFileCount ?? 0) > 0
    }

    private var isChecking: Bool {
        context == nil && error == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                RepositoryStatusIndicator(state: error == nil && context != nil && !hasChanges ? .ready : .working)
                Text(repository.displayName).lineLimit(1)
                Spacer()
                if error == nil {
                    Button(progress?.label ?? (hasChanges ? "Commit" : "Checkpoint"), action: onCommit)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(isChecking || progress != nil)
                }
                else { Button("Retry", action: onRetry).controlSize(.small) }
            }
            HStack(spacing: 6) {
                if progress != nil { ProgressView().controlSize(.small) }
                Text(
                    error == nil
                        ? (progress?.label ?? (isChecking ? "Checking repository…" : (hasChanges ? "\(context?.changedFileCount ?? 0) change(s) ready" : "Clean")))
                        : "Repository unavailable"
                )
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
