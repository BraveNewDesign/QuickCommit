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
        #expect(message.subject == "Add file: text.md")
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
}
