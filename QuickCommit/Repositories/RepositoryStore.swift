import Foundation
import Combine

@MainActor
final class RepositoryStore: ObservableObject {
    @Published private(set) var repositories: [RepositoryRecord] = []
    @Published private(set) var contexts: [UUID: CommitChangeContext] = [:]
    @Published private(set) var commitProgress: [UUID: CommitProgress] = [:]
    @Published private(set) var errors: [UUID: RepositoryError] = [:]
    @Published private(set) var isBusy = false
    @Published private(set) var launchAtLoginError: RepositoryError?
    @Published private(set) var generalError: RepositoryError?
    @Published var settings = AppSettings()
    private let stateStore = AppStateStore()
    private let access = RepositoryAccessManager()
    private let git: any GitServing
    private let coordinator: CommitCoordinator
    private var monitors: [UUID: RepositoryMonitor] = [:]
    private var started = false

    init(git: any GitServing = LibGit2Service()) { self.git = git; coordinator = CommitCoordinator(git: git) }

    func start() {
        guard !started else { return }
        started = true
        Task { @MainActor in
            guard let state = try? await stateStore.load() else { generalError = .persistenceFailed; return }
            repositories = state.repositories.sorted { $0.order < $1.order }; settings = state.settings
            settings.launchAtLogin = LaunchAtLoginService().isEnabled
            for record in repositories {
                await refresh(record)
                startMonitor(for: record)
            }
        }
    }

    func addRepository() {
        Task { @MainActor in
            do {
                let selected = try access.selectRepository(); defer { selected.lease.endAccess() }
                let selectedURL = selected.lease.url.standardizedFileURL.resolvingSymlinksInPath()
                for existing in repositories {
                    if let lease = try? access.access(existing) {
                        defer { lease.endAccess() }
                        if lease.url.standardizedFileURL.resolvingSymlinksInPath() == selectedURL { throw RepositoryError.duplicateRepository }
                    }
                }
                _ = try await git.inspectRepository(at: selected.lease.url)
                var record = selected.record; record.order = repositories.count; repositories.append(record)
                try await save(); await refresh(record)
                startMonitor(for: record)
            } catch let error as RepositoryError {
                if error != .selectionCancelled { generalError = error }
            } catch { generalError = .persistenceFailed }
        }
    }

    func refresh(_ record: RepositoryRecord) async {
        do {
            let resolved = try access.resolveAccess(record); defer { resolved.lease.endAccess() }
            if let bookmark = resolved.renewedBookmarkData, let index = repositories.firstIndex(where: { $0.id == record.id }) { repositories[index].bookmarkData = bookmark; try? await save() }
            contexts[record.id] = try await git.inspectRepository(at: resolved.lease.url); errors[record.id] = nil
        }
        catch let error as RepositoryError { errors[record.id] = error }
        catch { errors[record.id] = .unavailable }
    }

    func commit(_ record: RepositoryRecord) {
        Task { @MainActor in
            guard !isBusy else { return }
            isBusy = true
            defer { commitProgress[record.id] = nil }
            defer { isBusy = false }
            do {
                let store = self
                _ = try await coordinator.commit(record, settings: settings) { phase in
                    Task { @MainActor in store.commitProgress[record.id] = phase }
                }
                await refresh(record)
            }
            catch let error as RepositoryError { errors[record.id] = error }
            catch { errors[record.id] = .gitOperationFailed }
        }
    }

    func remove(_ record: RepositoryRecord) {
        monitors.removeValue(forKey: record.id)?.stop()
        repositories.removeAll { $0.id == record.id }; contexts[record.id] = nil; errors[record.id] = nil
        Task { @MainActor in
            do { try await save(); generalError = nil }
            catch { }
        }
    }
    private func startMonitor(for record: RepositoryRecord) {
        guard monitors[record.id] == nil, let lease = try? access.access(record) else { return }
        let monitor: RepositoryMonitor
        do {
            monitor = try RepositoryMonitor(url: lease.url, lease: lease) { [weak self] in
                Task { @MainActor [weak self] in await self?.refresh(record) }
            }
        } catch { lease.endAccess(); errors[record.id] = .monitoringFailed; return }
        monitors[record.id] = monitor
        if !monitor.start() { monitors[record.id] = nil; errors[record.id] = .monitoringFailed }
    }

    func persistSettings() {
        generalError = nil
        do { try LaunchAtLoginService().setEnabled(settings.launchAtLogin); launchAtLoginError = nil }
        catch { launchAtLoginError = .unavailable; settings.launchAtLogin = LaunchAtLoginService().isEnabled }
        Task { @MainActor in
            do { try await save(); generalError = nil }
            catch { }
        }
    }
    private func save() async throws {
        do { try await stateStore.save(PersistedAppState(repositories: repositories, settings: settings)) }
        catch { generalError = .persistenceFailed; throw error }
    }
}
