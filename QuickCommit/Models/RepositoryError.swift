enum RepositoryError: Error, Equatable, Sendable {
    case accessDenied
    case invalidRepository
    case bareRepository
    case conflictedRepository
    case gitRuntimeUnavailable
    case gitStatusFailed
    case gitOperationFailed
    case repositoryLocked
    case missingCommitIdentity
    case noChanges
    case persistenceFailed
    case staleBookmark
    case unavailable
}
