import Foundation
import libgit2

struct LibGit2Service: GitServing, Sendable {
    nonisolated init() {}
    func inspectRepository(at url: URL) async throws -> CommitChangeContext {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try LibGit2Runtime.acquire()
                defer { LibGit2Runtime.release() }
                let repository = try openRepository(at: url)
                defer { git_repository_free(repository) }
                let snapshot = try statusSnapshot(repository: repository)
                continuation.resume(returning: snapshot)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func openRepository(at url: URL) throws -> OpaquePointer {
        var repository: OpaquePointer?
        let result = git_repository_open(&repository, url.path)
        guard result == GIT_OK.rawValue, let repository else {
            throw LibGit2ErrorMapper.map(code: result)
        }
        guard git_repository_is_bare(repository) == 0 else {
            git_repository_free(repository)
            throw RepositoryError.bareRepository
        }
        return repository
    }

    func repositoryIdentity(at url: URL) async throws -> CommitIdentity? {
        try withRuntime(at: url) { repository in
            var signature: UnsafeMutablePointer<git_signature>?
            let result = git_signature_default(&signature, repository)
            guard result == GIT_OK.rawValue, let signature else { return nil }
            defer { git_signature_free(signature) }
            let value = signature.pointee
            guard let name = value.name, let email = value.email else { return nil }
            return CommitIdentity(name: String(cString: name), email: String(cString: email))
        }
    }

    func commitAllChanges(at url: URL, subject: String, identity: CommitIdentity) async throws -> CommitResult {
        try await stageAllChanges(at: url)
        return try await commitStagedChanges(at: url, subject: subject, identity: identity)
    }

    func stageAllChanges(at url: URL) async throws {
        try withRuntime(at: url) { repository in
            let before = try statusSnapshot(repository: repository)
            guard !before.hasConflicts else { throw RepositoryError.conflictedRepository }
            guard before.changedFileCount > 0 else { throw RepositoryError.noChanges }
            var index: OpaquePointer?
            var result = git_repository_index(&index, repository)
            guard result == GIT_OK.rawValue, let index else { throw LibGit2ErrorMapper.map(code: result) }
            defer { git_index_free(index) }
            result = git_index_add_all(index, nil, GIT_INDEX_ADD_DEFAULT.rawValue, nil, nil)
            guard result == GIT_OK.rawValue else { throw LibGit2ErrorMapper.map(code: result) }
            result = git_index_update_all(index, nil, nil, nil)
            guard result == GIT_OK.rawValue else { throw LibGit2ErrorMapper.map(code: result) }
            result = git_index_write(index)
            guard result == GIT_OK.rawValue else { throw LibGit2ErrorMapper.map(code: result) }
        }
    }

    func commitStagedChanges(at url: URL, subject: String, identity: CommitIdentity) async throws -> CommitResult {
        try withRuntime(at: url) { repository in
            var result: Int32
            var author: UnsafeMutablePointer<git_signature>?
            var committer: UnsafeMutablePointer<git_signature>?
            result = git_signature_now(&author, identity.name, identity.email)
            guard result == GIT_OK.rawValue, let author else { throw RepositoryError.gitOperationFailed }
            defer { git_signature_free(author) }
            result = git_signature_now(&committer, identity.name, identity.email)
            guard result == GIT_OK.rawValue, let committer else { throw RepositoryError.gitOperationFailed }
            defer { git_signature_free(committer) }

            var options = git_commit_create_options()
            options.version = 1
            options.allow_empty_commit = 0
            options.author = UnsafePointer(author)
            options.committer = UnsafePointer(committer)

            var commitOID = git_oid()
            result = subject.withCString { message in
                git_commit_create_from_stage(&commitOID, repository, message, &options)
            }
            guard result == GIT_OK.rawValue else { throw LibGit2ErrorMapper.map(code: result) }
            return .committed(subject: subject)
        }
    }

    private func withRuntime<T>(at url: URL, _ body: (OpaquePointer) throws -> T) throws -> T {
        try LibGit2Runtime.acquire()
        defer { LibGit2Runtime.release() }
        let repository = try openRepository(at: url)
        return try body(repository)
    }

    private func statusSnapshot(repository: OpaquePointer) throws -> CommitChangeContext {
        var options = git_status_options()
        guard git_status_options_init(&options, UInt32(GIT_STATUS_OPTIONS_VERSION)) == GIT_OK.rawValue else {
            throw RepositoryError.gitStatusFailed
        }
        options.flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED.rawValue
            | GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS.rawValue
            | GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX.rawValue
            | GIT_STATUS_OPT_RENAMES_INDEX_TO_WORKDIR.rawValue

        var list: OpaquePointer?
        let result = git_status_list_new(&list, repository, &options)
        guard result == GIT_OK.rawValue, let list else { throw LibGit2ErrorMapper.map(code: result) }
        defer { git_status_list_free(list) }

        var context = CommitChangeContext.empty
        context.changedFileCount = Int(git_status_list_entrycount(list))
        for index in 0..<git_status_list_entrycount(list) {
            guard let entry = git_status_byindex(list, index)?.pointee else { continue }
            let flags = entry.status.rawValue
            if let delta = entry.index_to_workdir ?? entry.head_to_index {
                let path = delta.pointee.new_file.path ?? delta.pointee.old_file.path
                if let path { context.paths.append(String(cString: path)) }
            }
            if flags & GIT_STATUS_CONFLICTED.rawValue != 0 { context.hasConflicts = true }
            if flags & GIT_STATUS_WT_DELETED.rawValue != 0 { context.deletedFileCount += 1 }
            if flags & GIT_STATUS_WT_NEW.rawValue != 0 { context.untrackedFileCount += 1 }
            if flags & (GIT_STATUS_WT_MODIFIED.rawValue | GIT_STATUS_INDEX_MODIFIED.rawValue) != 0 {
                context.modifiedFileCount += 1
            }
        }
        return context
    }
}
