import Foundation

protocol GitServing: Sendable {
    func inspectRepository(at url: URL) async throws -> CommitChangeContext
    func stageAllChanges(at url: URL) async throws
    func commitStagedChanges(at url: URL, subject: String, identity: CommitIdentity) async throws -> CommitResult
    func commitAllChanges(at url: URL, subject: String, identity: CommitIdentity) async throws -> CommitResult
    func repositoryIdentity(at url: URL) async throws -> CommitIdentity?
}
