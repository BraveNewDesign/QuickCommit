import Foundation

actor AppStateStore {
    private let fileManager: FileManager
    init(fileManager: FileManager = .default) { self.fileManager = fileManager }

    private var stateURL: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("QuickCommit", isDirectory: true).appendingPathComponent("State.json")
    }

    func load() throws -> PersistedAppState {
        guard fileManager.fileExists(atPath: stateURL.path) else { return PersistedAppState() }
        let data = try Data(contentsOf: stateURL)
        let state = try JSONDecoder().decode(PersistedAppState.self, from: data)
        if state.schemaVersion == PersistedAppState.currentSchemaVersion { return state }
        if state.schemaVersion == 1 { var migrated = state; migrated.schemaVersion = PersistedAppState.currentSchemaVersion; return migrated }
        throw RepositoryError.persistenceFailed
    }

    func save(_ state: PersistedAppState) throws {
        let directory = stateURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(state).write(to: stateURL, options: .atomic)
    }
}
