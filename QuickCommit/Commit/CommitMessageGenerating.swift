protocol CommitMessageGenerating: Sendable {
    func subject(for context: CommitChangeContext) async -> String
}
