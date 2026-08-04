protocol CommitMessageGenerating: Sendable {
    func message(for context: CommitChangeContext) async throws -> GeneratedCommitMessage
}

extension CommitMessageGenerating {
    func subject(for context: CommitChangeContext) async -> String {
        (try? await message(for: context).subject) ?? "Update project files"
    }
}
