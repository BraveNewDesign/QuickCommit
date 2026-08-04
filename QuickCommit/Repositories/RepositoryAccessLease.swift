import Foundation

final class RepositoryAccessLease: @unchecked Sendable {
    let url: URL
    private let lock = NSLock()
    private var active = true

    nonisolated init(url: URL) throws {
        self.url = url
        guard url.startAccessingSecurityScopedResource() else { throw RepositoryError.accessDenied }
    }

    nonisolated func endAccess() {
        lock.lock(); defer { lock.unlock() }
        guard active else { return }
        active = false
        url.stopAccessingSecurityScopedResource()
    }

    deinit { endAccess() }
}
