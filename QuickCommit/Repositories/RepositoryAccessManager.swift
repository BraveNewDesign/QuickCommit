import Foundation
import AppKit

struct RepositoryAccessManager: Sendable {
    struct ResolvedAccess: Sendable {
        let lease: RepositoryAccessLease
        let renewedBookmarkData: Data?
    }
    nonisolated init() {}
    @MainActor
    func selectRepository() throws -> (record: RepositoryRecord, lease: RepositoryAccessLease) {
        // Quick Commit is an agent/menu-bar app. Activate it before presenting
        // the panel so the Finder sidebar is interactive on the first launch.
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        guard panel.runModal() == .OK, let url = panel.url else { throw RepositoryError.selectionCancelled }
        guard FileManager.default.fileExists(atPath: url.appendingPathComponent(".git").path) else { throw RepositoryError.invalidRepository }
        let lease = try RepositoryAccessLease(url: url)
        let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        return (RepositoryRecord(displayName: url.lastPathComponent, bookmarkData: bookmark), lease)
    }

    nonisolated func access(_ repository: RepositoryRecord) throws -> RepositoryAccessLease {
        try resolveAccess(repository).lease
    }

    nonisolated func resolveAccess(_ repository: RepositoryRecord) throws -> ResolvedAccess {
        var stale = false
        let url = try URL(resolvingBookmarkData: repository.bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &stale)
        let lease = try RepositoryAccessLease(url: url)
        guard stale else { return ResolvedAccess(lease: lease, renewedBookmarkData: nil) }
        do { return ResolvedAccess(lease: lease, renewedBookmarkData: try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)) }
        catch { lease.endAccess(); throw RepositoryError.bookmarkRenewalFailed }
    }
}
