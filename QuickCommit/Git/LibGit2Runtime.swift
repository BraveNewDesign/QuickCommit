import Foundation
import libgit2

enum LibGit2Runtime {
    private static let lock = NSLock()
    private static var referenceCount = 0

    static func acquire() throws {
        lock.lock()
        defer { lock.unlock() }
        if referenceCount == 0, git_libgit2_init() < 0 {
            throw RepositoryError.gitRuntimeUnavailable
        }
        referenceCount += 1
    }

    static func release() {
        lock.lock()
        defer { lock.unlock() }
        guard referenceCount > 0 else { return }
        referenceCount -= 1
        if referenceCount == 0 { _ = git_libgit2_shutdown() }
    }
}
