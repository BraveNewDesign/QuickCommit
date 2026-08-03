import Foundation

final class RepositoryAccessLease: @unchecked Sendable {
    let url: URL
    nonisolated(unsafe) private var active = true

    nonisolated init(url: URL) throws {
        self.url = url
        guard url.startAccessingSecurityScopedResource() else { throw RepositoryError.accessDenied }
    }

    nonisolated func endAccess() {
        guard active else { return }
        active = false
        url.stopAccessingSecurityScopedResource()
    }

    deinit { endAccess() }
}
