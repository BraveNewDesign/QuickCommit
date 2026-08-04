import Foundation
import Combine

@MainActor
final class RepositoryStore: ObservableObject {
    @Published private(set) var repositories: [RepositoryRecord] = []
    @Published private(set) var contexts: [UUID: CommitChangeContext] = [:]
    @Published private(set) var commitProgress: [UUID: CommitProgress] = [:]
    @Published private(set) var errors: [UUID: RepositoryError] = [:]
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
            guard let state = try? await stateStore.load() else { return }
            repositories = state.repositories.sorted { $0.order < $1.order }; settings = state.settings
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
                _ = try await git.inspectRepository(at: selected.lease.url)
                var record = selected.record; record.order = repositories.count; repositories.append(record)
                try await save(); await refresh(record)
                startMonitor(for: record)
            } catch let error as RepositoryError { errors[UUID()] = error } catch { }
        }
    }

    func refresh(_ record: RepositoryRecord) async {
        do { let lease = try access.access(record); defer { lease.endAccess() }; contexts[record.id] = try await git.inspectRepository(at: lease.url); errors[record.id] = nil }
        catch let error as RepositoryError { errors[record.id] = error }
        catch { errors[record.id] = .unavailable }
    }

    func commit(_ record: RepositoryRecord) {
        Task { @MainActor in
            defer { commitProgress[record.id] = nil }
            do {
                _ = try await coordinator.commit(record, settings: settings) { [weak self] phase in
                    Task { @MainActor in self?.commitProgress[record.id] = phase }
                }
                await refresh(record)
            }
            catch let error as RepositoryError { errors[record.id] = error }
            catch { errors[record.id] = .gitOperationFailed }
        }
    }

    func remove(_ record: RepositoryRecord) { repositories.removeAll { $0.id == record.id }; Task { try? await save() } }
    private func startMonitor(for record: RepositoryRecord) {
        guard monitors[record.id] == nil, let lease = try? access.access(record) else { return }
        let monitor = RepositoryMonitor(url: lease.url, lease: lease) { [weak self] in
            Task { @MainActor in await self?.refresh(record) }
        }
        monitors[record.id] = monitor; monitor.start()
    }

    func persistSettings() { Task { try? await save() } }
    private func save() async throws { try await stateStore.save(PersistedAppState(repositories: repositories, settings: settings)) }
}
