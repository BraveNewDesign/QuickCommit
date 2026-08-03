struct FallbackCommitMessageGenerator: CommitMessageGenerating {
    nonisolated init() {}
    func subject(for context: CommitChangeContext) async -> String {
        if context.untrackedFileCount > 0 && context.modifiedFileCount == 0 { return "Add (context.untrackedFileCount) new file" + (context.untrackedFileCount == 1 ? "" : "s") }
        if context.deletedFileCount > 0 && context.modifiedFileCount == 0 { return "Remove (context.deletedFileCount) file" + (context.deletedFileCount == 1 ? "" : "s") }
        return context.changedFileCount == 1 ? "Update one file" : "Update (context.changedFileCount) files"
    }
}
