import Foundation

protocol GitServing: Sendable {
    func inspectRepository(at url: URL) async throws -> CommitChangeContext
    func resolveIdentity(at url: URL) async throws -> CommitIdentity?
    func prepareCheckpoint(at url: URL, identity: CommitIdentity) async throws -> PreparedCheckpoint
    func commitPreparedCheckpoint(_ prepared: PreparedCheckpoint, subject: String, identity: CommitIdentity) async throws -> CommitResult
    func rollbackPreparedCheckpoint(_ prepared: PreparedCheckpoint) async throws
}
