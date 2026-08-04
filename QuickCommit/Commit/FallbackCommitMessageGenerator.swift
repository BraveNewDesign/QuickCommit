import Foundation

struct FallbackCommitMessageGenerator: CommitMessageGenerating {
    nonisolated init() {}
    func message(for context: CommitChangeContext) async throws -> GeneratedCommitMessage {
        let subject: String
        let meaningfulPaths = context.paths.filter { !CommitChangeContext.isLikelyGeneratedPath($0) }
        let paths = meaningfulPaths.prefix(2).map { URL(fileURLWithPath: $0).lastPathComponent }
        let pathDescription = paths.joined(separator: " and ")
        let suffix = pathDescription.isEmpty ? "" : ": \(pathDescription)"
        if context.renamedFileCount > 0 && context.modifiedFileCount == 0 { subject = "Rename file\(suffix)" }
        else if context.untrackedFileCount > 0 && context.modifiedFileCount == 0 { subject = "Add file\(suffix)" }
        else if context.deletedFileCount > 0 && context.modifiedFileCount == 0 { subject = "Remove file\(suffix)" }
        else if context.changedFileCount == 1 { subject = "Update file\(suffix)" }
        else { subject = meaningfulPaths.isEmpty ? "Update repository metadata" : "Update \(context.changedFileCount) files" }
        return GeneratedCommitMessage(subject: subject, source: .fallback, fallbackReason: nil)
    }
}
