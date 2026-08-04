import Foundation
import libgit2

nonisolated enum LibGit2Runtime {
    private final class State: @unchecked Sendable {
        let lock = NSLock()
        var referenceCount = 0
    }
    private static let state = State()

    static func acquire() throws {
        state.lock.lock()
        defer { state.lock.unlock() }
        if state.referenceCount == 0, git_libgit2_init() < 0 {
            throw RepositoryError.gitRuntimeUnavailable
        }
        state.referenceCount += 1
    }

    static func release() {
        state.lock.lock()
        defer { state.lock.unlock() }
        guard state.referenceCount > 0 else { return }
        state.referenceCount -= 1
        if state.referenceCount == 0 { _ = git_libgit2_shutdown() }
    }
}
