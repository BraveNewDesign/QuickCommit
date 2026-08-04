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
    case repositoryOperationInProgress(RepositoryOperationState)
    case indexChangedExternally
    case invalidIdentity
    case bookmarkRenewalFailed
    case duplicateRepository
    case monitoringFailed
    case cancelled
    case selectionCancelled

    var userMessage: String {
        switch self {
        case .accessDenied: return "Quick Commit does not have access to this repository. Reauthorize it in Settings."
        case .staleBookmark, .bookmarkRenewalFailed: return "Repository access expired. Reauthorize this repository."
        case .invalidRepository: return "This folder is not a valid Git repository."
        case .bareRepository: return "Bare repositories are not supported."
        case .conflictedRepository: return "Resolve the repository conflicts before checkpointing."
        case .repositoryOperationInProgress(let operation): return "A Git \(operation.rawValue) operation is in progress. Finish or cancel it first."
        case .missingCommitIdentity, .invalidIdentity: return "Set a Git name and email in Settings, or configure them in the repository."
        case .noChanges: return "This repository is clean."
        case .repositoryLocked: return "Another checkpoint is in progress. Try again when it finishes."
        case .indexChangedExternally: return "The Git index changed during checkpointing. Quick Commit left it untouched."
        case .persistenceFailed: return "Quick Commit could not save its settings. Try again."
        case .duplicateRepository: return "This repository has already been added."
        case .selectionCancelled: return ""
        case .monitoringFailed: return "Live repository updates are unavailable. Retry to refresh manually."
        case .gitRuntimeUnavailable, .gitStatusFailed, .gitOperationFailed, .unavailable, .cancelled: return "Quick Commit could not checkpoint this repository. Try again."
        }
    }
}
