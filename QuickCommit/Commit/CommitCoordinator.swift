import Foundation

actor CommitCoordinator {
    private let git: any GitServing
    private let access: RepositoryAccessManager
    private let generator: any CommitMessageGenerating
    private var busy = false

    init(git: any GitServing = LibGit2Service(), access: RepositoryAccessManager = RepositoryAccessManager(), generator: any CommitMessageGenerating = FoundationCommitMessageGenerator()) {
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
        let identity: CommitIdentity?
        if let configured = settings.commitIdentity, configured.isUsable { identity = configured }
        else { identity = try await git.resolveIdentity(at: lease.url) }
        guard let identity else { throw RepositoryError.missingCommitIdentity }
        onProgress(.staging)
        let prepared = try await git.prepareCheckpoint(at: lease.url, identity: identity)
        onProgress(.generatingMessage)
        let generated: GeneratedCommitMessage
        do { generated = try await generator.message(for: context) }
        catch is CancellationError {
            try? await git.rollbackPreparedCheckpoint(prepared)
            throw RepositoryError.cancelled
        } catch {
            try? await git.rollbackPreparedCheckpoint(prepared)
            throw error
        }
        onProgress(.committing)
        do { return try await git.commitPreparedCheckpoint(prepared, subject: generated.subject, identity: identity) }
        catch {
            if case RepositoryError.indexChangedExternally = error { throw error }
            try? await git.rollbackPreparedCheckpoint(prepared)
            throw error
        }
    }
}
