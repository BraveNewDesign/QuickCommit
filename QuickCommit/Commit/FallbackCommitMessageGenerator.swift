struct FallbackCommitMessageGenerator: CommitMessageGenerating {
    nonisolated init() {}
    func message(for context: CommitChangeContext) async throws -> GeneratedCommitMessage {
        let subject: String
        if context.renamedFileCount > 0 && context.modifiedFileCount == 0 { subject = "Rename (context.renamedFileCount) file" + (context.renamedFileCount == 1 ? "" : "s") }
        else if context.untrackedFileCount > 0 && context.modifiedFileCount == 0 { subject = "Add \(context.untrackedFileCount) new file" + (context.untrackedFileCount == 1 ? "" : "s") }
        else if context.deletedFileCount > 0 && context.modifiedFileCount == 0 { subject = "Remove \(context.deletedFileCount) file" + (context.deletedFileCount == 1 ? "" : "s") }
        else { subject = context.changedFileCount == 1 ? "Update one file" : "Update \(context.changedFileCount) files" }
        return GeneratedCommitMessage(subject: subject, source: .fallback, fallbackReason: nil)
    }
}
