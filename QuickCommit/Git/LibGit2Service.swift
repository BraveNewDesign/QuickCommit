import CryptoKit
import Foundation
import libgit2
import OSLog

/// The single serialized boundary for every libgit2 object and operation.
actor LibGit2Service: GitServing {
    func inspectRepository(at url: URL) async throws -> CommitChangeContext {
        try withRuntime(at: url) { repository in
            let context = try statusSnapshot(repository: repository)
            guard context.repositoryOperation == .idle else {
                throw RepositoryError.repositoryOperationInProgress(context.repositoryOperation)
            }
            return context
        }
    }

    func resolveIdentity(at url: URL) async throws -> CommitIdentity? {
        try withRuntime(at: url) { repository in
            var signature: UnsafeMutablePointer<git_signature>?
            let result = git_signature_default(&signature, repository)
            guard result == GIT_OK.rawValue else {
                throw makeError(result)
            }
            guard let signature else { return nil }
            defer { git_signature_free(signature) }
            guard let name = signature.pointee.name, let email = signature.pointee.email else { return nil }
            let identity = CommitIdentity(name: String(cString: name), email: String(cString: email))
            return identity.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || identity.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : identity
        }
    }

    func prepareCheckpoint(at url: URL, identity: CommitIdentity) async throws -> PreparedCheckpoint {
        try withRuntime(at: url) { repository in
            let before = try statusSnapshot(repository: repository)
            guard before.repositoryOperation == .idle else { throw RepositoryError.repositoryOperationInProgress(before.repositoryOperation) }
            guard !before.hasConflicts else { throw RepositoryError.conflictedRepository }
            guard !before.isClean else { throw RepositoryError.noChanges }
            guard identity.isUsable else { throw RepositoryError.invalidIdentity }

            var index: OpaquePointer?
            var result = git_repository_index(&index, repository)
            guard result == GIT_OK.rawValue, let index else { throw makeError(result) }
            defer { git_index_free(index) }
            let priorData = try indexData(index)
            result = git_index_add_all(index, nil, GIT_INDEX_ADD_DEFAULT.rawValue, nil, nil)
            guard result == GIT_OK.rawValue else { throw makeError(result) }
            result = git_index_update_all(index, nil, nil, nil)
            guard result == GIT_OK.rawValue else { throw makeError(result) }
            result = git_index_write(index)
            guard result == GIT_OK.rawValue else { throw makeError(result) }
            let stagedFingerprint = try fingerprint(indexData(index))
            return PreparedCheckpoint(repositoryURL: url, context: before, priorIndexData: priorData, stagedIndexFingerprint: stagedFingerprint)
        }
    }

    func commitPreparedCheckpoint(_ prepared: PreparedCheckpoint, subject: String, identity: CommitIdentity) async throws -> CommitResult {
        try withRuntime(at: prepared.repositoryURL) { repository in
            guard identity.isUsable else { throw RepositoryError.invalidIdentity }
            var index: OpaquePointer?
            var result = git_repository_index(&index, repository)
            guard result == GIT_OK.rawValue, let index else { throw makeError(result) }
            defer { git_index_free(index) }
            guard try fingerprint(indexData(index)) == prepared.stagedIndexFingerprint else { throw RepositoryError.indexChangedExternally }
            guard git_index_entrycount(index) > 0 else { throw RepositoryError.noChanges }

            var author: UnsafeMutablePointer<git_signature>?
            var committer: UnsafeMutablePointer<git_signature>?
            result = git_signature_now(&author, identity.name, identity.email)
            guard result == GIT_OK.rawValue, let author else { throw makeError(result) }
            defer { git_signature_free(author) }
            result = git_signature_now(&committer, identity.name, identity.email)
            guard result == GIT_OK.rawValue, let committer else { throw makeError(result) }
            defer { git_signature_free(committer) }

            var options = git_commit_create_options()
            options.version = 1
            options.allow_empty_commit = 0
            options.author = UnsafePointer(author)
            options.committer = UnsafePointer(committer)
            var oid = git_oid()
            result = subject.withCString { message in git_commit_create_from_stage(&oid, repository, message, &options) }
            guard result == GIT_OK.rawValue else { throw makeError(result) }
            return .committed(subject: subject)
        }
    }

    func rollbackPreparedCheckpoint(_ prepared: PreparedCheckpoint) async throws {
        try withRuntime(at: prepared.repositoryURL) { repository in
            var index: OpaquePointer?
            var result = git_repository_index(&index, repository)
            guard result == GIT_OK.rawValue, let index else { throw makeError(result) }
            defer { git_index_free(index) }
            guard try fingerprint(indexData(index)) == prepared.stagedIndexFingerprint else { throw RepositoryError.indexChangedExternally }
            let path = try indexPath(index)
            try prepared.priorIndexData.write(to: URL(fileURLWithPath: path), options: .atomic)
            result = git_index_read(index, 1)
            guard result == GIT_OK.rawValue else { throw makeError(result) }
        }
    }

    private func withRuntime<T>(at url: URL, _ body: (OpaquePointer) throws -> T) throws -> T {
        try LibGit2Runtime.acquire()
        defer { LibGit2Runtime.release() }
        let repository = try openRepository(at: url)
        defer { git_repository_free(repository) }
        return try body(repository)
    }

    private func openRepository(at url: URL) throws -> OpaquePointer {
        var repository: OpaquePointer?
        let result = git_repository_open(&repository, url.path)
        guard result == GIT_OK.rawValue, let repository else { throw makeError(result) }
        guard git_repository_is_bare(repository) == 0 else {
            git_repository_free(repository)
            throw RepositoryError.bareRepository
        }
        return repository
    }

    private func statusSnapshot(repository: OpaquePointer) throws -> CommitChangeContext {
        var options = git_status_options()
        guard git_status_options_init(&options, UInt32(GIT_STATUS_OPTIONS_VERSION)) == GIT_OK.rawValue else { throw RepositoryError.gitStatusFailed }
        options.flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED.rawValue | GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS.rawValue | GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX.rawValue | GIT_STATUS_OPT_RENAMES_INDEX_TO_WORKDIR.rawValue
        var list: OpaquePointer?
        let result = git_status_list_new(&list, repository, &options)
        guard result == GIT_OK.rawValue, let list else { throw makeError(result) }
        defer { git_status_list_free(list) }
        var context = CommitChangeContext.empty
        context.repositoryOperation = operationState(repository: repository)
        let count = git_status_list_entrycount(list)
        context.changedFileCount = Int(count)
        for offset in 0..<count {
            guard let entry = git_status_byindex(list, offset)?.pointee else { continue }
            let flags = entry.status.rawValue
            let staged = flags & (GIT_STATUS_INDEX_NEW.rawValue | GIT_STATUS_INDEX_MODIFIED.rawValue | GIT_STATUS_INDEX_DELETED.rawValue | GIT_STATUS_INDEX_RENAMED.rawValue | GIT_STATUS_INDEX_TYPECHANGE.rawValue) != 0
            let unstaged = flags & (GIT_STATUS_WT_NEW.rawValue | GIT_STATUS_WT_MODIFIED.rawValue | GIT_STATUS_WT_DELETED.rawValue | GIT_STATUS_WT_RENAMED.rawValue | GIT_STATUS_WT_TYPECHANGE.rawValue) != 0
            if staged { context.stagedFileCount += 1 }
            if unstaged { context.unstagedFileCount += 1 }
            if flags & GIT_STATUS_CONFLICTED.rawValue != 0 { context.hasConflicts = true }
            if flags & (GIT_STATUS_WT_DELETED.rawValue | GIT_STATUS_INDEX_DELETED.rawValue) != 0 { context.deletedFileCount += 1 }
            if flags & (GIT_STATUS_WT_NEW.rawValue | GIT_STATUS_INDEX_NEW.rawValue) != 0 { context.untrackedFileCount += 1 }
            if flags & (GIT_STATUS_WT_MODIFIED.rawValue | GIT_STATUS_INDEX_MODIFIED.rawValue) != 0 { context.modifiedFileCount += 1 }
            if flags & (GIT_STATUS_WT_RENAMED.rawValue | GIT_STATUS_INDEX_RENAMED.rawValue) != 0 { context.renamedFileCount += 1 }
            if flags & (GIT_STATUS_WT_TYPECHANGE.rawValue | GIT_STATUS_INDEX_TYPECHANGE.rawValue) != 0 { context.typeChangedFileCount += 1 }
            if let delta = entry.index_to_workdir ?? entry.head_to_index, let path = delta.pointee.new_file.path ?? delta.pointee.old_file.path { context.paths.append(String(cString: path)) }
        }
        context.diffText = (try? diffText(repository: repository)) ?? ""
        return context
    }

    private func diffText(repository: OpaquePointer) throws -> String {
        var options = git_diff_options()
        let optionsResult = git_diff_options_init(&options, UInt32(GIT_DIFF_OPTIONS_VERSION))
        guard optionsResult == GIT_OK.rawValue else { throw RepositoryError.gitOperationFailed }
        options.flags = GIT_DIFF_INCLUDE_UNTRACKED.rawValue | GIT_DIFF_RECURSE_UNTRACKED_DIRS.rawValue | GIT_DIFF_SHOW_UNTRACKED_CONTENT.rawValue
        var diff: OpaquePointer?
        let result = git_diff_tree_to_workdir_with_index(&diff, repository, nil, &options)
        guard result == GIT_OK.rawValue, let diff else { throw makeError(result) }
        defer { git_diff_free(diff) }

        var buffer = git_buf()
        let bufferResult = git_diff_to_buf(&buffer, diff, GIT_DIFF_FORMAT_PATCH)
        defer { git_buf_dispose(&buffer) }
        guard bufferResult == GIT_OK.rawValue else { throw makeError(bufferResult) }
        guard let pointer = buffer.ptr else { return "" }
        return String(cString: pointer)
    }

    private func operationState(repository: OpaquePointer) -> RepositoryOperationState {
        guard let path = git_repository_path(repository) else { return .idle }
        let git = URL(fileURLWithPath: String(cString: path))
        let fm = FileManager.default
        if fm.fileExists(atPath: git.appendingPathComponent("MERGE_HEAD").path) { return .merge }
        if fm.fileExists(atPath: git.appendingPathComponent("REVERT_HEAD").path) { return .revert }
        if fm.fileExists(atPath: git.appendingPathComponent("CHERRY_PICK_HEAD").path) { return .cherryPick }
        if fm.fileExists(atPath: git.appendingPathComponent("BISECT_LOG").path) { return .bisect }
        if fm.fileExists(atPath: git.appendingPathComponent("rebase-merge").path) || fm.fileExists(atPath: git.appendingPathComponent("rebase-apply").path) { return .rebase }
        if fm.fileExists(atPath: git.appendingPathComponent("sequencer").path) { return .mailbox }
        return .idle
    }

    private func indexPath(_ index: OpaquePointer) throws -> String {
        guard let path = git_index_path(index) else { throw RepositoryError.gitOperationFailed }
        return String(cString: path)
    }

    private func indexData(_ index: OpaquePointer) throws -> Data {
        let url = URL(fileURLWithPath: try indexPath(index))
        guard FileManager.default.fileExists(atPath: url.path) else { return Data() }
        return try Data(contentsOf: url)
    }
    private func fingerprint(_ data: Data) throws -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }

    private func makeError(_ code: Int32) -> RepositoryError {
        let detail = git_error_last().map { String(cString: $0.pointee.message) }
        AppLogger.git.error("libgit2 operation failed: \(detail ?? "unknown")")
        return LibGit2ErrorMapper.map(code: code, message: detail)
    }
}
