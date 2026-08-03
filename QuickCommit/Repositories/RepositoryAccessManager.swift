import Foundation
import AppKit

struct RepositoryAccessManager: Sendable {
    nonisolated init() {}
    @MainActor
    func selectRepository() throws -> (record: RepositoryRecord, lease: RepositoryAccessLease) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        guard panel.runModal() == .OK, let url = panel.url else { throw RepositoryError.accessDenied }
        let lease = try RepositoryAccessLease(url: url)
        let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        return (RepositoryRecord(displayName: url.lastPathComponent, bookmarkData: bookmark), lease)
    }

    nonisolated func access(_ repository: RepositoryRecord) throws -> RepositoryAccessLease {
        var stale = false
        let url = try URL(resolvingBookmarkData: repository.bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &stale)
        if stale { throw RepositoryError.staleBookmark }
        return try RepositoryAccessLease(url: url)
    }
}
