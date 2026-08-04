import Foundation
import Testing
import libgit2
@testable import QuickCommit

struct ModelScaffoldTests {
    @Test func repositoryRecordHasStableIdentity() {
        let record = RepositoryRecord(displayName: "Example")
        #expect(!record.id.uuidString.isEmpty)
        #expect(record.displayName == "Example")
    }

    @Test(arguments: [0, 2])
    func fallbackMessageIsAvailable(for fileCount: Int) async {
        let context = CommitChangeContext(
            changedFileCount: fileCount,
            modifiedFileCount: fileCount,
            untrackedFileCount: 0,
            deletedFileCount: 0,
            hasConflicts: false,
            paths: []
        )
        let message = await FallbackCommitMessageGenerator().subject(for: context)
        #expect(!message.isEmpty)
    }

    @Test func fallbackMessageNamesSingleChangedFile() async throws {
        let context = CommitChangeContext(
            changedFileCount: 1,
            modifiedFileCount: 0,
            untrackedFileCount: 1,
            deletedFileCount: 0,
            hasConflicts: false,
            paths: ["text.md"]
        )

        let message = try await FallbackCommitMessageGenerator().message(for: context)
        #expect(message.subject == "Add text.md")
    }

    @Test func messageQualityRejectsGeneratedFileFocus() {
        let context = CommitChangeContext(
            changedFileCount: 3,
            modifiedFileCount: 0,
            untrackedFileCount: 3,
            deletedFileCount: 0,
            hasConflicts: false,
            paths: [".DS_Store", "README.md", "life.md"]
        )

        let quality = CommitMessageQualityEvaluator.evaluate("Add file: .DS_Store and life.md", for: context)
        #expect(quality.issues.contains(.mentionsGeneratedFile))
        #expect(!quality.isAcceptable)
    }

    @Test(arguments: [
        ("Add text.md", true),
        ("Fix repository access errors", true),
        ("Configure repository identity", true),
        ("Refine README.md guidance", true),
        ("Rename notes.md to archive.md", true),
        ("Delete obsolete fixture", true),
        ("Update 3 files", false),
        ("Add file: text.md", false),
        ("updated project files", false),
        ("Update README.md.", false),
        ("Update README.md\nwith details", false),
        ("This commit message is intentionally much too long because useful subjects should remain concise and easy to scan in history", false)
    ])
    func messageQualityMeasuresUsefulSubjects(subject: String, acceptable: Bool) {
        let context = CommitChangeContext(
            changedFileCount: 1,
            modifiedFileCount: 1,
            untrackedFileCount: 0,
            deletedFileCount: 0,
            hasConflicts: false,
            paths: ["text.md"]
        )

        #expect(CommitMessageQualityEvaluator.evaluate(subject, for: context).isAcceptable == acceptable)
    }

    @Test func fallbackMessageFiltersGeneratedFiles() async throws {
        let context = CommitChangeContext(
            changedFileCount: 3,
            modifiedFileCount: 0,
            untrackedFileCount: 3,
            deletedFileCount: 0,
            hasConflicts: false,
            paths: [".DS_Store", "README.md", "life.md"]
        )

        let message = try await FallbackCommitMessageGenerator().message(for: context)
        #expect(!message.subject.contains(".DS_Store"))
        #expect(message.subject.contains("README.md"))
    }

    @Test func fallbackMessageAvoidsCountOnlySubject() async throws {
        let context = CommitChangeContext(
            changedFileCount: 3,
            modifiedFileCount: 2,
            untrackedFileCount: 1,
            deletedFileCount: 0,
            hasConflicts: false,
            paths: ["README.md", "life.md", "config.json"]
        )

        let message = try await FallbackCommitMessageGenerator().message(for: context)
        #expect(message.subject == "Update README.md, life.md, and 1 more")
        #expect(CommitMessageQualityEvaluator.evaluate(message.subject, for: context).isAcceptable)
    }

    @Test func foundationModelQualityFailureUsesFallback() async throws {
        let context = CommitChangeContext(
            changedFileCount: 1,
            modifiedFileCount: 1,
            untrackedFileCount: 0,
            deletedFileCount: 0,
            hasConflicts: false,
            paths: ["README.md"]
        )
        let generator = FoundationCommitMessageGenerator(
            client: FixedFoundationModelClient(output: "Update 1 file")
        )

        let message = try await generator.message(for: context)
        #expect(message.source == .fallback)
        #expect(message.subject == "Update README.md")
        #expect(message.fallbackReason != nil)
    }

    @Test func missingRepositoryIdentityReturnsNil() async throws {
        let directory = try await makeEmptyRepository()
        defer { try? FileManager.default.removeItem(at: directory) }
        try clearRepositoryIdentity(at: directory)

        let identity = try await LibGit2Service().resolveIdentity(at: directory)
        #expect(identity == nil)
    }

    @Test func inProgressRepositoryOperationIsRejected() async throws {
        let directory = try await makeEmptyRepository()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("pending\n".utf8).write(to: directory.appendingPathComponent(".git/MERGE_HEAD"))

        do {
            _ = try await LibGit2Service().inspectRepository(at: directory)
            #expect(Bool(false))
        } catch let error as RepositoryError {
            #expect(error == .repositoryOperationInProgress(.merge))
        }
    }

    @Test func libGit2CommitStagesAndCommitsAllChanges() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuickCommitTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try LibGit2Runtime.acquire()
        var repository: OpaquePointer?
        let initResult = git_repository_init(&repository, directory.path, 0)
        #expect(initResult == GIT_OK.rawValue)
        if let repository { git_repository_free(repository) }
        LibGit2Runtime.release()

        let file = directory.appendingPathComponent("note.txt")
        try Data("first\n".utf8).write(to: file)

        let service = LibGit2Service()
        let identity = CommitIdentity(name: "QuickCommit Tests", email: "quickcommit-tests@example.com")
        let initial = try await service.prepareCheckpoint(at: directory, identity: identity)
        _ = try await service.commitPreparedCheckpoint(initial, subject: "Initial checkpoint", identity: identity)

        try Data("second\n".utf8).write(to: file)
        let prepared = try await service.prepareCheckpoint(at: directory, identity: identity)
        let result = try await service.commitPreparedCheckpoint(prepared, subject: "Update checkpoint", identity: identity)
        #expect(result == .committed(subject: "Update checkpoint"))

        let context = try await service.inspectRepository(at: directory)
        #expect(context.changedFileCount == 0)
    }

    private func makeEmptyRepository() async throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuickCommitTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for attempt in 0..<20 {
            try LibGit2Runtime.acquire()
            var repository: OpaquePointer?
            let result = git_repository_init(&repository, directory.path, 0)
            if let repository { git_repository_free(repository) }
            LibGit2Runtime.release()
            if result == GIT_OK.rawValue { return directory }
            if result != -14 || attempt == 19 { break }
            try await Task.sleep(for: .milliseconds(25))
        }
        throw RepositoryError.gitOperationFailed
    }

    private func clearRepositoryIdentity(at directory: URL) throws {
        try LibGit2Runtime.acquire()
        defer { LibGit2Runtime.release() }
        var repository: OpaquePointer?
        let openResult = git_repository_open(&repository, directory.path)
        #expect(openResult == GIT_OK.rawValue)
        guard let repository else { throw RepositoryError.gitOperationFailed }
        defer { git_repository_free(repository) }
        var config: OpaquePointer?
        let configResult = git_repository_config(&config, repository)
        #expect(configResult == GIT_OK.rawValue)
        guard let config else { throw RepositoryError.gitOperationFailed }
        defer { git_config_free(config) }
        #expect(git_config_set_string(config, "user.name", "") == GIT_OK.rawValue)
        #expect(git_config_set_string(config, "user.email", "") == GIT_OK.rawValue)
    }
}

private struct FixedFoundationModelClient: FoundationModelClient {
    let output: String

    func generate(context: CommitChangeContext) async throws -> String {
        output
    }
}
