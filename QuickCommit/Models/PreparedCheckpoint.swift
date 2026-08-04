import Foundation

struct PreparedCheckpoint: Sendable, Equatable {
    let repositoryURL: URL
    let context: CommitChangeContext
    let priorIndexData: Data
    let stagedIndexFingerprint: String
}

struct GeneratedCommitMessage: Equatable, Sendable {
    enum Source: String, Sendable { case appleIntelligence, fallback }
    let subject: String
    let source: Source
    let fallbackReason: String?
}
