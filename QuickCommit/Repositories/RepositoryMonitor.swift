import Foundation
import CoreServices

final class RepositoryMonitor: @unchecked Sendable {
    private var stream: FSEventStreamRef?
    private let queue = DispatchQueue(label: "com.bravenewdesign.QuickCommit.monitor")
    private let callback: @Sendable () -> Void
    private let lease: RepositoryAccessLease

    init(url: URL, lease: RepositoryAccessLease, callback: @escaping @Sendable () -> Void) throws {
        self.lease = lease
        self.callback = callback
        var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        stream = FSEventStreamCreate(nil, { _, info, _, _, _, _ in
            guard let info else { return }
            Unmanaged<RepositoryMonitor>.fromOpaque(info).takeUnretainedValue().callback()
        }, &context, [url.path] as CFArray, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0.25, FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagIgnoreSelf))
        guard stream != nil else { lease.endAccess(); throw RepositoryError.monitoringFailed }
    }

    @discardableResult
    func start() -> Bool {
        guard let stream else { return false }
        FSEventStreamSetDispatchQueue(stream, queue)
        return FSEventStreamStart(stream)
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream); FSEventStreamInvalidate(stream); FSEventStreamRelease(stream); self.stream = nil
    }

    deinit { stop(); lease.endAccess() }
}
