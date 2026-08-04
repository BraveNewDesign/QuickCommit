import Foundation

actor CommitCoordinator {
    private let git: any GitServing
    private let access: RepositoryAccessManager
    private let generator: any CommitMessageGenerating
    private var busy = false

    init(git: any GitServing = LibGit2Service(), access: RepositoryAccessManager = RepositoryAccessManager(), generator: any CommitMessageGenerating = FallbackCommitMessageGenerator()) {
        self.git = git; self.access = access; self.generator = generator
    }

    func commit(
        _ record: RepositoryRecord,
        settings: AppSettings,
        onProgress: @escaping @Sendable (CommitProgress) -> Void = { _ in }
    ) async throws -> CommitResult {
        guard !busy else { throw RepositoryError.repositoryLocked }
        busy = true; defer { busy = false }
        let lease = try access.access(record); defer { lease.endAccess() }
        let context = try await git.inspectRepository(at: lease.url)
        guard !context.hasConflicts else { throw RepositoryError.conflictedRepository }
        guard context.changedFileCount > 0 else { throw RepositoryError.noChanges }
        onProgress(.staging)
        try await git.stageAllChanges(at: lease.url)
        let identity: CommitIdentity?
        if let configured = settings.commitIdentity { identity = configured }
        else { identity = try await git.repositoryIdentity(at: lease.url) }
        guard let identity else { throw RepositoryError.missingCommitIdentity }
        onProgress(.generatingMessage)
        let subject = await generator.subject(for: context)
        onProgress(.committing)
        return try await git.commitStagedChanges(at: lease.url, subject: subject, identity: identity)
    }
}
